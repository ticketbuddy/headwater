defmodule Headwater.Aggregate.AggregateTest do
  use ExUnit.Case
  alias Headwater.Aggregate.AggregateWorker
  alias Headwater.AggregateDirectory.WriteRequest
  alias Headwater.EventStoreAdapters.Postgres.HeadwaterEventsSchema

  import Mox
  setup :set_mox_global
  setup :verify_on_exit!

  setup do
    Mox.stub_with(Headwater.Aggregate.HandlerMock, Headwater.Aggregate.HandlerStub)
    Mox.stub_with(Headwater.ListenerMock, Headwater.ListenerStub)
    :ok
  end

  @aggregate %Headwater.Aggregate.AggregateWorker{
    id: "aggregate-one",
    handler: Headwater.Aggregate.HandlerMock,
    registry: :fake_registry,
    supervisor: :fake_supervisor,
    event_store: Headwater.EventStoreMock
  }

  test "init/1" do
    assert {:ok, %{aggregate: @aggregate}} == AggregateWorker.init(%{aggregate: @aggregate})
  end

  describe "handles a new wish" do
    @wish %FakeApp.ScorePoint{}
    @event %FakeApp.PointScored{}
    @aggregate_id "aggregate-one"
    @idempotency_key "idem-12345"

    @msg {:wish, @aggregate_id, @wish, @idempotency_key}
    @from self()

    @state %{
      aggregate: @aggregate,
      aggregate_state: %FakeApp{},
      last_event_id: 3
    }

    test "when handler execute and next_state succeed" do
      Headwater.Aggregate.HandlerMock
      |> expect(:execute, fn current_state = %FakeApp{}, wish = @wish ->
        Headwater.Aggregate.HandlerStub.execute(current_state, wish)
      end)

      Headwater.Aggregate.HandlerMock
      |> expect(:next_state, fn current_state = %FakeApp{}, event = @event ->
        Headwater.Aggregate.HandlerStub.next_state(current_state, event)
      end)

      Headwater.EventStoreMock
      |> expect(:commit!, fn @aggregate_id, last_event_id = 3, [@event], @idempotency_key ->
        {:ok, 4}
      end)

      assert {:reply, {:ok, {4, %FakeApp{total: 1}}},
              %{
                last_event_id: 4,
                aggregate: %Headwater.Aggregate.AggregateWorker{
                  event_store: Headwater.EventStoreMock,
                  handler: Headwater.Aggregate.HandlerMock,
                  id: "aggregate-one",
                  registry: :fake_registry,
                  supervisor: :fake_supervisor
                },
                aggregate_state: %FakeApp{total: 1}
              }} == AggregateWorker.handle_call(@msg, @from, @state)
    end

    test "when wish has already succeeded" do
      Headwater.EventStoreMock
      |> expect(:commit!, fn _aggregate_id, _last_event_id, _event, _idempotency_key ->
        {:error, :wish_already_completed}
      end)

      assert {:reply, {:ok, {3, %FakeApp{}}},
              %{
                last_event_id: 3,
                aggregate: %Headwater.Aggregate.AggregateWorker{
                  event_store: Headwater.EventStoreMock,
                  handler: Headwater.Aggregate.HandlerMock,
                  id: "aggregate-one",
                  registry: :fake_registry,
                  supervisor: :fake_supervisor
                },
                aggregate_state: %FakeApp{}
              }} == AggregateWorker.handle_call(@msg, @from, @state)
    end
  end

  describe "when handler.execute fails" do
    test "when has NOT been previously successful" do
      Headwater.Aggregate.HandlerMock
      |> expect(:execute, fn current_state, event ->
        {:error, :not_enough_lemonade}
      end)

      Headwater.EventStoreMock
      |> expect(:has_wish_previously_succeeded?, fn @idempotency_key ->
        false
      end)

      assert {:reply, {:error, :execute, {:error, :not_enough_lemonade}}, @state} ==
               AggregateWorker.handle_call(@msg, @from, @state)
    end

    test "when HAS been previously successful" do
      Headwater.Aggregate.HandlerMock
      |> expect(:execute, fn current_state, event ->
        {:error, :execute, :not_enough_lemonade}
      end)

      Headwater.EventStoreMock
      |> expect(:has_wish_previously_succeeded?, fn @idempotency_key ->
        true
      end)

      assert {:reply, {:ok, {3, %FakeApp{}}}, @state} ==
               AggregateWorker.handle_call(@msg, @from, @state)
    end
  end

  describe "when handler.next_state fails" do
    test "returns next_state error" do
      Headwater.Aggregate.HandlerMock
      |> expect(:next_state, fn current_state, event ->
        {:error, :not_enough_fanta}
      end)

      assert {:reply, {:error, :next_state, {:error, :not_enough_fanta}}, @state} ==
               AggregateWorker.handle_call(@msg, @from, @state)
    end
  end

  describe "on first aggregate action" do
    setup do
      children = [
        {Registry, keys: :unique, name: FakeApp.Registry},
        {DynamicSupervisor, name: FakeApp.AggregateSupervisor, strategy: :one_for_one}
      ]

      {:ok, _pid} = Supervisor.start_link(children, strategy: :one_for_one)

      :ok
    end

    test "loads events and commits successful event to the event store & notifies listeners" do
      idempotency_key = Headwater.uuid()

      FakeApp.EventStoreMock
      |> expect(:load, fn "game-one" ->
        {:ok,
         [
           %HeadwaterEventsSchema{
             aggregate_id: "game-one",
             event: %FakeApp.PointScored{},
             event_ref: 1,
             event_id: 1
           }
         ], 1}
      end)

      FakeApp.EventStoreMock
      |> expect(:commit!, fn "game-one",
                             last_event_id = 1,
                             events = [%FakeApp.PointScored{}],
                             ^idempotency_key ->
        {:ok, 2}
      end)

      Headwater.Aggregate.HandlerMock
      |> expect(:execute, fn state, %FakeApp.ScorePoint{} ->
        {:ok, %FakeApp.PointScored{}}
      end)

      Headwater.Aggregate.HandlerMock
      |> expect(:next_state, fn nil, %FakeApp.PointScored{} ->
        %FakeApp{total: 1}
      end)

      Headwater.Aggregate.HandlerMock
      |> expect(:next_state, fn %FakeApp{}, %FakeApp.PointScored{} ->
        %FakeApp{total: 1}
      end)

      Headwater.ListenerMock
      |> expect(:check_for_new_data, fn ->
        :ok
      end)

      %WriteRequest{
        aggregate_id: "game-one",
        handler: Headwater.Aggregate.HandlerMock,
        wish: %FakeApp.ScorePoint{},
        idempotency_key: idempotency_key
      }
      |> FakeApp.Headwater.AggregateDirectory.handle()
    end
  end
end

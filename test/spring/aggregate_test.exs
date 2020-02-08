defmodule Headwater.Spring.AggregateTest do
  use ExUnit.Case
  alias Headwater.Spring.Aggregate
  alias Headwater.Spring.WriteRequest

  import Mox
  setup :set_mox_global
  setup :verify_on_exit!

  setup do
    Mox.stub_with(Headwater.Spring.HandlerMock, Headwater.Spring.HandlerStub)
    :ok
  end

  @aggregate %Headwater.Spring.Aggregate{
    id: "aggregate-one",
    handler: Headwater.Spring.HandlerMock,
    registry: :fake_registry,
    supervisor: :fake_supervisor,
    event_store: Headwater.EventStoreMock
  }

  test "init/1" do
    assert {:ok, %{aggregate: @aggregate}} == Aggregate.init(%{aggregate: @aggregate})
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
      Headwater.Spring.HandlerMock
      |> expect(:execute, fn current_state = %FakeApp{}, wish = @wish ->
        Headwater.Spring.HandlerStub.execute(current_state, wish)
      end)

      Headwater.Spring.HandlerMock
      |> expect(:next_state, fn current_state = %FakeApp{}, event = @event ->
        Headwater.Spring.HandlerStub.next_state(current_state, event)
      end)

      Headwater.EventStoreMock
      |> expect(:commit!, fn @aggregate_id, last_event_id = 3, @event, @idempotency_key ->
        {:ok, 4}
      end)

      assert {:reply, {:ok, {4, %FakeApp{total: 1}}},
              %{
                last_event_id: 4,
                aggregate: %Headwater.Spring.Aggregate{
                  event_store: Headwater.EventStoreMock,
                  handler: Headwater.Spring.HandlerMock,
                  id: "aggregate-one",
                  registry: :fake_registry,
                  supervisor: :fake_supervisor
                },
                aggregate_state: %FakeApp{total: 1}
              }} == Aggregate.handle_call(@msg, @from, @state)
    end

    test "when wish has already succeeded" do
      Headwater.EventStoreMock
      |> expect(:commit!, fn _aggregate_id, _last_event_id, _event, _idempotency_key ->
        {:error, :wish_already_completed}
      end)

      assert {:reply, {:ok, {3, %FakeApp{}}},
              %{
                last_event_id: 3,
                aggregate: %Headwater.Spring.Aggregate{
                  event_store: Headwater.EventStoreMock,
                  handler: Headwater.Spring.HandlerMock,
                  id: "aggregate-one",
                  registry: :fake_registry,
                  supervisor: :fake_supervisor
                },
                aggregate_state: %FakeApp{}
              }} == Aggregate.handle_call(@msg, @from, @state)
    end
  end

  describe "when handler.execute fails" do
    test "when has NOT been previously successful" do
      Headwater.Spring.HandlerMock
      |> expect(:execute, fn current_state, event ->
        {:error, :not_enough_lemonade}
      end)

      Headwater.EventStoreMock
      |> expect(:has_wish_previously_succeeded?, fn @idempotency_key ->
        false
      end)

      assert {:reply, {:error, :execute, {:error, :not_enough_lemonade}}, @state} ==
               Aggregate.handle_call(@msg, @from, @state)
    end

    test "when HAS been previously successful" do
      Headwater.Spring.HandlerMock
      |> expect(:execute, fn current_state, event ->
        {:error, :execute, :not_enough_lemonade}
      end)

      Headwater.EventStoreMock
      |> expect(:has_wish_previously_succeeded?, fn @idempotency_key ->
        true
      end)

      assert {:reply, {:ok, {3, %FakeApp{}}}, @state} ==
               Aggregate.handle_call(@msg, @from, @state)
    end
  end

  describe "when handler.next_state fails" do
    test "returns next_state error" do
      Headwater.Spring.HandlerMock
      |> expect(:next_state, fn current_state, event ->
        {:error, :not_enough_fanta}
      end)

      assert {:reply, {:error, :next_state, {:error, :not_enough_fanta}}, @state} ==
               Aggregate.handle_call(@msg, @from, @state)
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

    test "loads events and commits successful event to the event store" do
      idempotency_key = Headwater.Spring.uuid()

      FakeApp.EventStoreMock
      |> expect(:load, fn "game-one" ->
        {:ok, [], 0}
      end)

      FakeApp.EventStoreMock
      |> expect(:commit!, fn "game-one",
                             last_event_id = 0,
                             events = %FakeApp.PointScored{},
                             ^idempotency_key ->
        {:ok, 1}
      end)

      Headwater.Spring.HandlerMock
      |> expect(:execute, fn nil, %FakeApp.ScorePoint{} ->
        {:ok, %FakeApp.PointScored{}}
      end)

      Headwater.Spring.HandlerMock
      |> expect(:next_state, fn nil, %FakeApp.PointScored{} ->
        %FakeApp{}
      end)

      %WriteRequest{
        aggregate_id: "game-one",
        handler: Headwater.Spring.HandlerMock,
        wish: %FakeApp.ScorePoint{},
        idempotency_key: idempotency_key
      }
      |> FakeApp.Headwater.Spring.handle()
    end
  end
end

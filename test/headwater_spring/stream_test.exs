defmodule HeadwaterSpring.StreamTest do
  use ExUnit.Case
  alias HeadwaterSpring.Stream

  import Mox
  setup :verify_on_exit!

  setup do
    Mox.stub_with(HeadwaterSpring.HandlerMock, HeadwaterSpring.HandlerStub)
    :ok
  end

  @stream %HeadwaterSpring.Stream{
    id: "stream-one",
    handler: HeadwaterSpring.HandlerMock,
    registry: :fake_registry,
    supervisor: :fake_supervisor,
    event_store: HeadwaterSpring.EventStoreMock
  }

  test "init/1" do
    assert {:ok, %{stream: @stream}} == Stream.init(%{stream: @stream})
  end

  describe "handles a new wish" do
    @wish %FakeApp.ScorePoint{}
    @event %FakeApp.PointScored{}
    @stream_id "stream-one"
    @idempotency_key "idem-12345"

    @msg {:wish, @stream_id, @wish, @idempotency_key}
    @from self()

    @state %{
      stream: @stream,
      stream_state: %FakeApp{},
      last_event_id: 3
    }

    test "when handler execute and next_state succeed" do
      HeadwaterSpring.HandlerMock
      |> expect(:execute, fn current_state = %FakeApp{}, wish = @wish ->
        HeadwaterSpring.HandlerStub.execute(current_state, wish)
      end)

      HeadwaterSpring.HandlerMock
      |> expect(:next_state, fn current_state = %FakeApp{}, event = @event ->
        HeadwaterSpring.HandlerStub.next_state(current_state, event)
      end)

      HeadwaterSpring.EventStoreMock
      |> expect(:commit!, fn @stream_id, last_event_id = 3, @event, @idempotency_key ->
        {:ok, 4}
      end)

      assert {:reply, {:ok, {4, %FakeApp{total: 1}}},
              %{
                last_event_id: 4,
                stream: %HeadwaterSpring.Stream{
                  event_store: HeadwaterSpring.EventStoreMock,
                  handler: HeadwaterSpring.HandlerMock,
                  id: "stream-one",
                  registry: :fake_registry,
                  supervisor: :fake_supervisor
                },
                stream_state: %FakeApp{total: 1}
              }} == Stream.handle_call(@msg, @from, @state)
    end

    test "when wish has already succeeded" do
      HeadwaterSpring.EventStoreMock
      |> expect(:commit!, fn _stream_id, _last_event_id, _event, _idempotency_key ->
        {:error, :wish_already_completed}
      end)

      assert {:reply, {:ok, {3, %FakeApp{}}},
              %{
                last_event_id: 3,
                stream: %HeadwaterSpring.Stream{
                  event_store: HeadwaterSpring.EventStoreMock,
                  handler: HeadwaterSpring.HandlerMock,
                  id: "stream-one",
                  registry: :fake_registry,
                  supervisor: :fake_supervisor
                },
                stream_state: %FakeApp{}
              }} == Stream.handle_call(@msg, @from, @state)
    end
  end

  describe "when handler.execute fails" do
    test "when has NOT been previously successful" do
      HeadwaterSpring.HandlerMock
      |> expect(:execute, fn current_state, event ->
        {:error, :not_enough_lemonade}
      end)

      HeadwaterSpring.EventStoreMock
      |> expect(:has_wish_previously_succeeded?, fn @idempotency_key ->
        false
      end)

      assert {:reply, {:error, :execute, {:error, :not_enough_lemonade}}, @state} ==
               Stream.handle_call(@msg, @from, @state)
    end

    test "when HAS been previously successful" do
      HeadwaterSpring.HandlerMock
      |> expect(:execute, fn current_state, event ->
        {:error, :execute, :not_enough_lemonade}
      end)

      HeadwaterSpring.EventStoreMock
      |> expect(:has_wish_previously_succeeded?, fn @idempotency_key ->
        true
      end)

      assert {:reply, {:ok, {3, %FakeApp{}}}, @state} ==
               Stream.handle_call(@msg, @from, @state)
    end
  end

  describe "when handler.next_state fails" do
    test "returns next_state error" do
      HeadwaterSpring.HandlerMock
      |> expect(:next_state, fn current_state, event ->
        {:error, :not_enough_fanta}
      end)

      assert {:reply, {:error, :next_state, {:error, :not_enough_fanta}}, @state} ==
               Stream.handle_call(@msg, @from, @state)
    end
  end
end

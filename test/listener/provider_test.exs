defmodule Headwater.Listener.ProviderTest do
  use ExUnit.Case
  import Mox
  setup :set_mox_global
  setup :verify_on_exit!

  setup do
    %{
      recorded_events: %{
        one: %Headwater.EventStore.RecordedEvent{
          aggregate_id: "aggregate-id-abcdef",
          event_id: "aaa-bbb-ccc-ddd-eee",
          event_number: 4,
          aggregate_number: 4,
          data: 1,
          created_at: ~U[2020-02-20 18:06:31.495494Z],
          idempotency_key: "idempo-4535"
        },
        two: %Headwater.EventStore.RecordedEvent{
          aggregate_id: "aggregate-id-abcdef",
          event_id: "fff-ggg-hhh-iii-jjj",
          event_number: 5,
          aggregate_number: 5,
          data: 1,
          created_at: ~U[2020-02-20 18:06:31.495494Z],
          idempotency_key: "idempo-4535"
        }
      }
    }
  end

  describe "handle_demand/2" do
    test "when pending demand does NOT reach zero", %{recorded_events: recorded_events} do
      latest_event_ref = 3
      queue = :queue.new()
      queue = :queue.in(recorded_events.one, queue)
      queue = :queue.in(recorded_events.two, queue)
      state = {queue, _pending_demand = 1, latest_event_ref}

      opts = %{
        event_store: FakeApp.EventStoreMock,
        bus_id: "a-big-sparkly-red-bus",
        from_event_ref: 0
      }

      expected_state =
        {_expected_queue = {[], []}, _pending_demand = 499, _expected_next_event_number = 3}

      assert {:noreply, [recorded_events.one, recorded_events.two], {expected_state, opts}} ==
               Headwater.Listener.Provider.handle_demand(_demand = 500, {state, opts})
    end

    test "when pending demand does reach zero", %{recorded_events: recorded_events} do
      latest_event_ref = 3
      queue = :queue.new()
      queue = :queue.in(recorded_events.one, queue)
      queue = :queue.in(recorded_events.two, queue)
      state = {queue, _pending_demand = 0, latest_event_ref}

      opts = %{
        event_store: FakeApp.EventStoreMock,
        bus_id: "a-big-sparkly-red-bus",
        from_event_ref: 0
      }

      expected_state =
        {_expected_queue = {[], [recorded_events.two]}, _pending_demand = 0,
         _expected_next_event_number = 3}

      assert {:noreply, [recorded_events.one], {expected_state, opts}} ==
               Headwater.Listener.Provider.handle_demand(_demand = 1, {state, opts})
    end
  end

  describe "checking for recorded events" do
    test "when pending demand does reach zero", %{recorded_events: recorded_events} do
      latest_event_ref = 3
      state = {:queue.new(), _pending_demand = 1, latest_event_ref}

      opts = %{
        event_store: FakeApp.EventStoreMock,
        bus_id: "a-big-sparkly-red-bus",
        from_event_ref: 0
      }

      FakeApp.EventStoreMock
      |> expect(:load_events, fn ^latest_event_ref ->
        [
          recorded_events.one,
          recorded_events.two
        ]
      end)

      expected_state =
        {_expected_queue = {[], [recorded_events.two]}, _pending_demand = 0,
         _expected_next_event_number = 5}

      assert {:noreply, [recorded_events.one], {expected_state, opts}} ==
               Headwater.Listener.Provider.handle_info(:check_for_recorded_events, {state, opts})
    end

    test "when pending demand does not reach zero", %{
      recorded_events: recorded_events
    } do
      latest_event_ref = 3
      state = {:queue.new(), _pending_demand = 500, latest_event_ref}

      opts = %{
        event_store: FakeApp.EventStoreMock,
        bus_id: "a-big-sparkly-red-bus",
        from_event_ref: 0
      }

      FakeApp.EventStoreMock
      |> expect(:load_events, fn ^latest_event_ref ->
        [
          recorded_events.one,
          recorded_events.two
        ]
      end)

      expected_state =
        {_expected_queue = {[], []}, _pending_demand = 498, _expected_next_event_number = 5}

      assert {:noreply, [recorded_events.one, recorded_events.two], {expected_state, opts}} ==
               Headwater.Listener.Provider.handle_info(:check_for_recorded_events, {state, opts})
    end
  end
end

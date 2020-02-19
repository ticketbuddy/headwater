defmodule Headwater.Aggregate.AggregateTest do
  use ExUnit.Case

  describe "Listener processes events in order" do
    test "when the requested event_ref IS the current event_ref + 1" do
      latest_event_ref = 0
      pending_demand = 5
      queue = :queue.new()

      state = {queue, pending_demand, latest_event_ref}
      event_ref = 1

      expected_flushed_events = [1]
      expected_pending_demand = 4
      expected_event_ref = 1
      expected_queue = {[], []}

      assert {:noreply, expected_flushed_events,
              {expected_queue, expected_pending_demand, expected_event_ref}} ==
               SecondExampleListener.Provider.handle_info({:new_event_ref, event_ref}, state)
    end

    test "when the requested event_ref is NOT the current event_ref + 1" do
      latest_event_ref = 0
      pending_demand = 5
      queue = :queue.new()

      state = {queue, pending_demand, latest_event_ref}
      event_ref = 10

      assert {:noreply, expected_flushed_events = [1, 2, 3, 4, 5],
              {_queue, _expected_pending_demand = 0, _latest_event_ref = 10}} =
               SecondExampleListener.Provider.handle_info({:new_event_ref, event_ref}, state)
    end
  end
end

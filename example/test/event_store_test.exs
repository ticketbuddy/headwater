defmodule Example.EventStoreTest do
  use ExUnit.Case

  describe "queries for recorded events" do
    test "retrieves event records that an event bus has not yet processed" do
      from_event_number = 3
      bus_id = "big-red-bus"

      {:ok, recorded_event_stream} =
        Example.EventStore.next_recorded_events_for_listener(bus_id, from_event_number)

      assert recorded_event_stream |> Enum.to_list() == [
               %Headwater.EventStore.RecordedEvent{
                 aggregate_id: "many-events",
                 aggregate_number: 3,
                 created_at: ~U[2020-02-22 19:09:35Z],
                 data: %Example.Incremented{counter_id: "many-events", increment_by: 7},
                 event_id: "c102dbcc-e37b-4edc-ba84-d46f0b83ebc5",
                 event_number: 4,
                 idempotency_key: "2d9e90ea88524b45bd1988eb735ea2b4"
               },
               %Headwater.EventStore.RecordedEvent{
                 aggregate_id: "many-events",
                 aggregate_number: 4,
                 created_at: ~U[2020-02-22 19:09:35Z],
                 data: %Example.Incremented{counter_id: "many-events", increment_by: 7},
                 event_id: "c624fd51-9dfd-4f9f-ade5-e1960edadeda",
                 event_number: 5,
                 idempotency_key: "2d9e90ea88524b45bd1988eb735ea2b4"
               }
             ]
    end
  end
end

defmodule Example.EventStoreTest do
  use ExUnit.Case
  use Example.Test.Support.Helper, :persist

  test "loads the events in the correct order, and with the correct last_event_id" do
    assert {:ok,
            [
              %Headwater.EventStoreAdapters.Postgres.HeadwaterEventsSchema{
                event: %Example.Incremented{
                  counter_id: "event-ordering",
                  increment_by: 10
                },
                event_id: 1,
                event_ref: 5,
                aggregate_id: "event-ordering"
              },
              %Headwater.EventStoreAdapters.Postgres.HeadwaterEventsSchema{
                event: %Example.Incremented{
                  counter_id: "event-ordering",
                  increment_by: 20
                },
                event_id: 2,
                event_ref: 6,
                aggregate_id: "event-ordering"
              }
            ], 2} = Example.EventStore.load_events("event-ordering")
  end

  describe "fetching the next event ref" do
    test "if the bus does not have any values" do
      base_event_ref = 5
      bus_id = "a-new-event_bus-not-played-an-event-yet"
      assert 5 == Example.EventStore.get_next_event_ref(bus_id, base_event_ref)
    end

    test "returns the latest event ref from the db" do
      base_event_ref = 5
      bus_id = "event_bus-one"
      assert 15 == Example.EventStore.get_next_event_ref(bus_id, base_event_ref)
    end
  end

  describe "&has_wish_previously_succeeded?/1" do
    test "when idempotency key HAS been used" do
      assert Example.EventStore.has_wish_previously_succeeded?("7ccdc378a8a64e979ea2d1e1af27b56d")
    end

    test "when idempotency key has NOT been used" do
      refute Example.EventStore.has_wish_previously_succeeded?(
               "this-idempotency-key-has-not-been-used"
             )
    end
  end
end

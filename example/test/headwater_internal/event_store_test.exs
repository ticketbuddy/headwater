defmodule Example.HeadwaterInternal.EventStoreTest do
  use ExUnit.Case
  use Headwater.TestHelper, repo: Example.Repo

  test "writes & reads one event" do
    aggregate_id = "counter_" <> Headwater.uuid()

    Example.Router.handle(%Example.Increment{
      counter_id: aggregate_id,
      increment_by: 5
    })

    assert result =
             [
               %{
                 aggregate_id: aggregate_id,
                 aggregate_number: 1,
                 created_at: _created_at,
                 data: %{counter_id: aggregate_id, increment_by: 5},
                 event_id: _event_id,
                 event_number: _event_number,
                 event_type: "Elixir.Example.Incremented",
                 idempotency_key: _indempotency_key
               }
             ] =
             Example.EventStore.load_events_for_aggregate(aggregate_id)
             |> Headwater.Debug.to_list()

    assert Enum.count(result) == 1
  end
end

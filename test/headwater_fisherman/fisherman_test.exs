defmodule HeadwaterFisherman.FishermanTest do
  use ExUnit.Case
  alias HeadwaterFisherman.Fisherman.EventHandlerMock
  alias HeadwaterSpring.EventStoreAdapters.Postgres.HeadwaterEventsSchema

  import Mox
  setup :set_mox_global
  setup :verify_on_exit!

  setup do
    FakeApp.EventStoreMock
    |> expect(:get_next_event_ref, fn _bus_id, _base_event_ref ->
      1
    end)

    test_pid = self()

    FakeApp.EventStoreMock
    |> expect(:bus_has_completed_event_ref, fn _event_ref ->
      send(test_pid, :bus_has_completed_event_ref)
      :ok
    end)

    FakeApp.EventStoreMock
    |> expect(:read_events, fn _fetch_opts ->
      [
        %HeadwaterEventsSchema{
          event_id: 1,
          event_ref: 1,
          stream_id: "game-one",
          idempotency_key: "f3e9ee81b8cd4283a40a4093b3ed551b",
          event: ~s({"__struct__":"Elixir.FakeApp.PointScored","game_id":"game-one","value":5})
        }
      ]
    end)

    :ok
  end

  test "on startup, it checks for events" do
    FakeApp.PrinterMock
    |> expect(:handle_event, fn _event, _notes ->
      :ok
    end)

    FakeAppFisherman.Producer.start_link([])
    FakeAppFisherman.Consumer.start_link([])

    assert_receive(:bus_has_completed_event_ref, 7500)
  end
end

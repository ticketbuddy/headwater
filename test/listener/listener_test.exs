defmodule Headwater.Listener.ListenerTest do
  use ExUnit.Case
  alias Headwater.Listener.EventHandlerMock
  alias Headwater.EventStoreAdapters.Postgres.HeadwaterEventsSchema

  import Mox
  setup :set_mox_global
  setup :verify_on_exit!

  setup do
    fake_event = %Elixir.FakeApp.PointScored{
      value: 5,
      game_id: "game-one"
    }

    FakeApp.EventStoreMock
    |> expect(:get_next_event_ref, fn "fake_app_bus_consumer", 0 ->
      1
    end)

    test_pid = self()

    FakeApp.EventStoreMock
    |> expect(:bus_has_completed_event_ref, fn [bus_id: "fake_app_bus_consumer", event_ref: 1] ->
      send(test_pid, :bus_has_completed_event_ref)
      :ok
    end)

    FakeApp.EventStoreMock
    |> expect(:read_events, fn [from_event_ref: 1, limit: 1000] ->
      [
        %HeadwaterEventsSchema{
          event_id: 1,
          event_ref: 1,
          stream_id: "game-one",
          idempotency_key: "f3e9ee81b8cd4283a40a4093b3ed551b",
          event: fake_event,
          inserted_at: ~U[2010-10-10 10:10:10Z]
        }
      ]
    end)

    %{fake_event: fake_event}
  end

  test "on startup, it checks for events", %{fake_event: fake_event} do
    FakeApp.PrinterMock
    |> expect(:handle_event, fn ^fake_event,
                                %{
                                  effect_idempotent_key: _,
                                  event_occurred_at: ~U[2010-10-10 10:10:10Z],
                                  event_ref: 1,
                                  stream_id: "game-one"
                                } ->
      :ok
    end)

    FakeAppListener.Producer.start_link([])
    FakeAppListener.Consumer.start_link([])

    assert_receive(:bus_has_completed_event_ref, 500)
  end
end

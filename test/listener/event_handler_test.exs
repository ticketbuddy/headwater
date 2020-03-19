defmodule Headwater.Listener.EventHandlerTest do
  use ExUnit.Case
  alias Headwater.Listener.EventHandler

  import Mox
  setup :set_mox_global
  setup :verify_on_exit!

  setup do
    %{
      recorded_events: %{
        one: %Headwater.EventStore.RecordedEvent{
          aggregate_id: "aggregate-id-abcdef",
          event_id: "zzz-xxx-ccc-vvv-fff",
          event_number: 50,
          aggregate_number: 1,
          data: 1,
          created_at: ~U[2020-02-20 18:06:31.495494Z],
          idempotency_key: "idempo-4535"
        },
        two: %Headwater.EventStore.RecordedEvent{
          aggregate_id: "aggregate-id-abcdef",
          event_id: "kkk-qqq-rrr-ppp-ooo",
          event_number: 52,
          aggregate_number: 2,
          data: 1,
          created_at: ~U[2020-02-20 18:06:31.495494Z],
          idempotency_key: "idempo-4535"
        }
      }
    }
  end

  test "build_callbacks/2", %{recorded_events: recorded_events} do
    recorded_events_list = [recorded_events.one, recorded_events.two]
    handlers = [:handler_a, :handler_b]

    assert [
             {recorded_events.one, [:handler_a, :handler_b]},
             {recorded_events.two, [:handler_a, :handler_b]}
           ] == EventHandler.build_callbacks(recorded_events_list, handlers)
  end

  describe "callbacks/2" do
    test "happy path", %{recorded_events: recorded_events} do
      FakeApp.PrinterMock
      |> expect(:listener_prefix, 2, fn -> "yellow_bus_" end)

      FakeApp.PrinterMock
      |> expect(:handle_event, 2, fn _recorded_event, _notes -> {:ok, "a result"} end)

      FakeApp.EventStoreMock
      |> expect(:bus_has_completed_event_number, 2, fn _opts -> :ok end)

      handlers = [FakeApp.PrinterMock]
      opts = %{event_store: FakeApp.EventStoreMock, bus_id: "yellow-bus"}
      recorded_events = [recorded_events.one, recorded_events.two]

      callbacks = EventHandler.build_callbacks(recorded_events, handlers)

      assert :ok == EventHandler.callbacks(callbacks, opts)
    end

    test "halts processing callbakcs if a callback fails", %{recorded_events: recorded_events} do
      FakeApp.PrinterMock
      |> expect(:listener_prefix, fn -> "yellow_bus_" end)

      FakeApp.PrinterMock
      |> expect(:handle_event, 1, fn _recorded_event, _notes ->
        {:error, "oh no, something went wrong"}
      end)

      FakeApp.EventStoreMock
      |> expect(:bus_has_completed_event_number, 0, fn _opts ->
        flunk("this should never be called!")
      end)

      handlers = [FakeApp.PrinterMock]
      opts = %{event_store: FakeApp.EventStoreMock, bus_id: "yellow-bus"}
      recorded_events = [recorded_events.one, recorded_events.two]

      callbacks = EventHandler.build_callbacks(recorded_events, handlers)

      assert {:error, :callback_errors} == EventHandler.callbacks(callbacks, opts)
    end

    test "when callback returns a wish to be submitted"

    test "when a callback returns a list of wishes to be submitted"
  end
end

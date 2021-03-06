defmodule Headwater.Listener.EventHandlerTest do
  use ExUnit.Case
  alias Headwater.Listener.EventHandler
  alias Headwater.Aggregate.Directory.WriteRequest

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
          event_number: 51,
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
      FakeApp.EventHandlerMock
      |> expect(:listener_prefix, 2, fn -> "yellow_bus_" end)

      FakeApp.EventHandlerMock
      |> expect(:handle_event, 2, fn _recorded_event, _notes -> {:ok, "a result"} end)

      FakeApp.EventStoreMock
      |> expect(:bus_has_completed_event_number, 2, fn
        [bus_id: "yellow-bus", event_number: 50] -> :ok
        [bus_id: "yellow-bus", event_number: 51] -> :ok
      end)

      handlers = [FakeApp.EventHandlerMock]
      opts = %{event_store: FakeApp.EventStoreMock, bus_id: "yellow-bus", router: FakeApp}
      recorded_events = [recorded_events.one, recorded_events.two]

      callbacks = EventHandler.build_callbacks(recorded_events, handlers)

      assert :ok == EventHandler.callbacks(callbacks, opts)
    end

    test "halts processing callbakcs if a callback fails", %{recorded_events: recorded_events} do
      FakeApp.EventHandlerMock
      |> expect(:listener_prefix, fn -> "yellow_bus_" end)

      FakeApp.EventHandlerMock
      |> expect(:handle_event, 1, fn _recorded_event = 1,
                                     %{
                                       aggregate_number: 1,
                                       effect_idempotent_key: "146243694CA13B32ADC5AFD0FC775598",
                                       event_id: "zzz-xxx-ccc-vvv-fff",
                                       event_number: 50,
                                       event_occurred_at: ~U[2020-02-20 18:06:31.495494Z]
                                     } ->
        {:error, "oh no, something went wrong"}
      end)

      FakeApp.EventStoreMock
      |> expect(:bus_has_completed_event_number, 0, fn _opts ->
        flunk("this should never be called!")
      end)

      handlers = [FakeApp.EventHandlerMock]
      opts = %{event_store: FakeApp.EventStoreMock, bus_id: "yellow-bus", router: FakeApp}
      recorded_events = [recorded_events.one, recorded_events.two]

      callbacks = EventHandler.build_callbacks(recorded_events, handlers)

      assert {:error, :callback_errors} == EventHandler.callbacks(callbacks, opts)
    end

    test "when callback returns a wish to be submitted", %{recorded_events: recorded_events} do
      FakeApp.EventHandlerMock
      |> expect(:listener_prefix, fn -> "yellow_bus_" end)

      FakeApp.EventHandlerMock
      |> expect(:handle_event, fn _recorded_event = 1,
                                  %{
                                    aggregate_number: 1,
                                    effect_idempotent_key: "146243694CA13B32ADC5AFD0FC775598",
                                    event_id: "zzz-xxx-ccc-vvv-fff",
                                    event_number: 50,
                                    event_occurred_at: ~U[2020-02-20 18:06:31.495494Z]
                                  } ->
        {:submit, %FakeApp.ScorePoint{game_id: "game_8790ce86756844c18e6ac51708524e7e", value: 1}}
      end)

      FakeApp.EventStoreMock
      |> expect(:bus_has_completed_event_number, 1, fn _opts ->
        :ok
      end)

      Headwater.Aggregate.DirectoryMock
      |> expect(:handle, fn _, _ ->
        {:ok, %FakeApp.Game{}}
      end)

      handlers = [FakeApp.EventHandlerMock]
      opts = %{event_store: FakeApp.EventStoreMock, bus_id: "yellow-bus", router: FakeApp}
      recorded_events = [recorded_events.one]

      callbacks = EventHandler.build_callbacks(recorded_events, handlers)

      assert :ok == EventHandler.callbacks(callbacks, opts)
    end

    test "when a callback returns a list of wishes to be submitted", %{
      recorded_events: recorded_events
    } do
      FakeApp.EventHandlerMock
      |> expect(:listener_prefix, fn -> "yellow_bus_" end)

      FakeApp.EventHandlerMock
      |> expect(:handle_event, fn _event = 1,
                                  %{
                                    aggregate_number: 1,
                                    effect_idempotent_key: "146243694CA13B32ADC5AFD0FC775598",
                                    event_id: "zzz-xxx-ccc-vvv-fff",
                                    event_number: 50,
                                    event_occurred_at: ~U[2020-02-20 18:06:31.495494Z]
                                  } ->
        {:submit,
         [
           %FakeApp.ScorePoint{game_id: "game_8790ce86756844c18e6ac51708524e7e", value: 1},
           %FakeApp.ScoreTwoPoints{}
         ]}
      end)

      FakeApp.EventStoreMock
      |> expect(:bus_has_completed_event_number, 1, fn _opts ->
        :ok
      end)

      Headwater.Aggregate.DirectoryMock
      |> expect(:handle, 2, fn _, _ ->
        {:ok, %FakeApp.Game{}}
      end)

      handlers = [FakeApp.EventHandlerMock]
      opts = %{event_store: FakeApp.EventStoreMock, bus_id: "yellow-bus", router: FakeApp}
      recorded_events = [recorded_events.one]

      callbacks = EventHandler.build_callbacks(recorded_events, handlers)

      assert :ok == EventHandler.callbacks(callbacks, opts)
    end

    test "when handler returns wishes with options", %{recorded_events: recorded_events} do
      FakeApp.EventHandlerMock
      |> expect(:listener_prefix, fn -> "yellow_bus_" end)

      FakeApp.EventHandlerMock
      |> expect(:handle_event, fn _event = 1,
                                  %{
                                    aggregate_number: 1,
                                    effect_idempotent_key: "146243694CA13B32ADC5AFD0FC775598",
                                    event_id: "zzz-xxx-ccc-vvv-fff",
                                    event_number: 50,
                                    event_occurred_at: ~U[2020-02-20 18:06:31.495494Z]
                                  } ->
        {:submit,
         [
           {%FakeApp.ScoreTwoPoints{}, idempotency_key: "abcdef"}
         ]}
      end)

      FakeApp.EventStoreMock
      |> expect(:bus_has_completed_event_number, 1, fn [bus_id: "yellow-bus", event_number: 50] ->
        :ok
      end)

      Headwater.Aggregate.DirectoryMock
      |> expect(:handle, fn
        %WriteRequest{idempotency_key: "abcdef"}, %Headwater.Config{} -> {:ok, %FakeApp.Game{}}
      end)

      handlers = [FakeApp.EventHandlerMock]
      opts = %{event_store: FakeApp.EventStoreMock, bus_id: "yellow-bus", router: FakeApp}
      recorded_events = [recorded_events.one]

      callbacks = EventHandler.build_callbacks(recorded_events, handlers)

      assert :ok == EventHandler.callbacks(callbacks, opts)
    end

    test "when handler returns a function call instruction", %{recorded_events: recorded_events} do
      FakeApp.EventHandlerMock
      |> expect(:listener_prefix, fn -> "yellow_bus_" end)

      FakeApp.EventHandlerMock
      |> expect(:handle_event, fn _event = 1,
                                  %{
                                    aggregate_number: 1,
                                    effect_idempotent_key: "146243694CA13B32ADC5AFD0FC775598",
                                    event_id: "zzz-xxx-ccc-vvv-fff",
                                    event_number: 50,
                                    event_occurred_at: ~U[2020-02-20 18:06:31.495494Z]
                                  } ->
        {:apply, Kernel, :send, [self(), :_external_api_do_something]}
      end)

      FakeApp.EventStoreMock
      |> expect(:bus_has_completed_event_number, 1, fn [bus_id: "yellow-bus", event_number: 50] ->
        :ok
      end)

      handlers = [FakeApp.EventHandlerMock]
      opts = %{event_store: FakeApp.EventStoreMock, bus_id: "yellow-bus", router: FakeApp}
      recorded_events = [recorded_events.one]

      callbacks = EventHandler.build_callbacks(recorded_events, handlers)

      assert :ok == EventHandler.callbacks(callbacks, opts)

      assert_receive(:_external_api_do_something, 5000)
    end
  end
end

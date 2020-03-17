defmodule Headwater.Listener.ConsumerTest do
  use ExUnit.Case
  import Mox
  setup :set_mox_global
  setup :verify_on_exit!

  setup do
    opts = %{
      bus_id: "a-consumer-test-bus-id",
      event_store: FakeApp.EventStoreMock,
      handlers: [FakeApp.PrinterMock]
    }

    %{
      opts: opts,
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
          data: 3745,
          created_at: ~U[2020-02-20 18:06:31.495494Z],
          idempotency_key: "idempo-4535"
        }
      }
    }
  end

  describe "handle_events/3" do
    test "happy path", %{opts: opts, recorded_events: recorded_events} do
      from_pid = self()
      state = opts

      FakeApp.PrinterMock
      |> expect(:listener_prefix, 2, fn -> "a_listener_prefix_" end)

      FakeApp.PrinterMock
      |> expect(:handle_event, 2, fn
        _expected_event = 1,
        %{
          aggregate_number: 4,
          effect_idempotent_key: _idempotency_key,
          event_id: "aaa-bbb-ccc-ddd-eee",
          event_number: 4,
          event_occurred_at: _event_occurred_at
        } ->
          :ok

        _expected_event = 3745,
        %{
          aggregate_number: 5,
          effect_idempotent_key: _idempotency_key,
          event_id: "fff-ggg-hhh-iii-jjj",
          event_number: 5,
          event_occurred_at: _event_occurred_at
        } ->
          :ok
      end)

      FakeApp.EventStoreMock
      |> expect(:bus_has_completed_event_number, 2, fn
        [bus_id: "a-consumer-test-bus-id", event_number: 4] -> :ok
        [bus_id: "a-consumer-test-bus-id", event_number: 5] -> :ok
      end)

      assert {:noreply, [], state} ==
               Headwater.Listener.Consumer.handle_events(
                 [recorded_events.one, recorded_events.two],
                 from_pid,
                 state
               )
    end

    test "unhappy path", %{opts: opts, recorded_events: recorded_events} do
      from_pid = self()
      state = opts

      FakeApp.PrinterMock
      |> expect(:listener_prefix, 2, fn -> "a_listener_prefix_" end)

      FakeApp.PrinterMock
      |> expect(:handle_event, 2, fn
        _expected_event = 1,
        %{
          aggregate_number: 4,
          effect_idempotent_key: _idempotency_key,
          event_id: "aaa-bbb-ccc-ddd-eee",
          event_number: 4,
          event_occurred_at: _event_occurred_at
        } ->
          :ok

        _expected_event = 3745,
        %{
          aggregate_number: 5,
          effect_idempotent_key: _idempotency_key,
          event_id: "fff-ggg-hhh-iii-jjj",
          event_number: 5,
          event_occurred_at: _event_occurred_at
        } ->
          :error
      end)

      FakeApp.EventStoreMock
      |> expect(:bus_has_completed_event_number, 1, fn
        [bus_id: "a-consumer-test-bus-id", event_number: 4] -> :ok
        [bus_id: "a-consumer-test-bus-id", event_number: 5] -> :ok
      end)

      assert_raise RuntimeError, fn ->
        Headwater.Listener.Consumer.handle_events(
          [recorded_events.one, recorded_events.two],
          from_pid,
          state
        )
      end
    end
  end
end

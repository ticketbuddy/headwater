defmodule Headwater.Aggregate.NextStateTest do
  use ExUnit.Case
  alias Headwater.Aggregate.NextState

  defmodule FakeHandler do
    def next_state(state, event) do
      state + event
    end
  end

  describe "NextState.process/3" do
    test "builds a state" do
      aggregate_state = 0

      recorded_events = [
        %Headwater.EventStore.RecordedEvent{
          aggregate_id: "counter-a",
          event_id: "aaa-bbb-ccc-ddd-eee",
          event_number: 50,
          aggregate_number: 3,
          data: 1,
          created_at: ~U[2020-02-20 18:06:31.495494Z]
        },
        %Headwater.EventStore.RecordedEvent{
          aggregate_id: "counter-a",
          event_id: "aaa-bbb-ccc-ddd-eee",
          event_number: 52,
          aggregate_number: 4,
          data: 3,
          created_at: ~U[2020-02-20 18:06:31.495494Z]
        },
        %Headwater.EventStore.RecordedEvent{
          aggregate_id: "counter-a",
          event_id: "aaa-bbb-ccc-ddd-eee",
          event_number: 56,
          aggregate_number: 5,
          data: 7,
          created_at: ~U[2020-02-20 18:06:31.495494Z]
        }
      ]

      resulting_state = NextState.process(FakeHandler, aggregate_state, recorded_events)

      expected_state = 11
      expected_aggregate_number = 5

      assert {:ok, expected_state, expected_aggregate_number} == resulting_state
    end
  end
end

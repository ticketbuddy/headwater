defmodule Headwater.Aggregate.AggregateWorkerTest do
  use ExUnit.Case
  alias Headwater.Aggregate.{AggregateWorker, AggregateConfig}
  alias Headwater.EventStore.RecordedEvent

  import Mox
  setup :set_mox_global
  setup :verify_on_exit!

  setup do
    defmodule MySupervisor do
      use DynamicSupervisor

      def init(args), do: args
    end

    {:ok, supervisor_pid} = DynamicSupervisor.start_link(MySupervisor, {:ok, %{}})
    {:ok, _} = Registry.start_link(keys: :unique, name: AggregateWorkerTesting.Registry)

    %{supervisor: supervisor_pid, registry: AggregateWorkerTesting.Registry}
  end

  describe "starting a new aggregate worker" do
    test "loads events and builds aggregate state", %{registry: registry, supervisor: supervisor} do
      FakeApp.EventStoreMock
      |> expect(:load_events, fn "aggregate-id-abcdef" ->
        {:ok,
         [
           %Headwater.EventStore.RecordedEvent{
             aggregate_id: "aggregate-id-abcdef",
             event_id: "aaa-bbb-ccc-ddd-eee",
             event_number: 50,
             aggregate_number: 1,
             data: 1,
             created_at: ~U[2020-02-20 18:06:31.495494Z]
           }
         ]}
      end)

      Headwater.Aggregate.HandlerMock
      |> expect(:next_state, fn current_state = nil, event = 1 ->
        5
      end)

      aggregate_config = %AggregateConfig{
        id: "aggregate-id-abcdef",
        handler: Headwater.Aggregate.HandlerMock,
        registry: registry,
        supervisor: supervisor,
        event_store: FakeApp.EventStoreMock,
        aggregate_state: nil
      }

      assert {:ok, _pid} = AggregateWorker.new(aggregate_config)
      assert {:ok, 5} == AggregateWorker.current_state(aggregate_config)
      assert {:ok, 1} == AggregateWorker.latest_aggregate_number(aggregate_config)
    end
  end
end

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
      |> expect(:load_events, fn "aggregate-id-abc" ->
        {:ok,
         [
           %Headwater.EventStore.RecordedEvent{
             aggregate_id: "counter-a",
             event_id: "aaa-bbb-ccc-ddd-eee",
             event_number: 50,
             aggregate_number: 3,
             data: 1,
             created_at: ~U[2020-02-20 18:06:31.495494Z]
           }
         ]}
      end)

      Headwater.Aggregate.HandlerMock
      |> expect(:next_state, fn current_state = nil, event = 1 ->
        5
      end)

      start_result =
        %AggregateConfig{
          id: "aggregate-id-abc",
          handler: Headwater.Aggregate.HandlerMock,
          registry: registry,
          supervisor: supervisor,
          event_store: FakeApp.EventStoreMock,
          aggregate_state: nil
        }
        |> AggregateWorker.new()

      assert {:ok, _pid} = start_result
    end
  end
end

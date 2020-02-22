defmodule Headwater.Aggregate.AggregateWorkerTest do
  use ExUnit.Case
  alias Headwater.Aggregate.{AggregateWorker, AggregateConfig}

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

  test "starts a new aggregate worker", %{registry: registry, supervisor: supervisor} do
    FakeApp.EventStoreMock
    |> expect(:load_events, fn "aggregate-id-abc" ->
      {:ok, []}
    end)

    start_result =
      %AggregateConfig{
        id: "aggregate-id-abc",
        handler: nil,
        registry: registry,
        supervisor: supervisor,
        event_store: FakeApp.EventStoreMock,
        aggregate_state: nil
      }
      |> AggregateWorker.new()

    assert {:ok, _pid} = start_result
  end
end

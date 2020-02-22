defmodule Headwater.AggregateDirectory.ResultTest do
  use ExUnit.Case
  alias Headwater.Aggregate.AggregateConfig

  defmodule MyState do
    defstruct [:name, :age]
  end

  test "when the aggregate is empty" do
    aggregate_config = %AggregateConfig{
      id: "agg-12345",
      handler: Handler,
      registry: nil,
      supervisor: nil,
      event_store: nil,
      aggregate_state: nil,
      aggregate_number: 0
    }

    assert {:warn, :empty_aggregate} ==
             Headwater.AggregateDirectory.Result.new({:ok, aggregate_config})
  end

  test "when aggregate has state" do
    aggregate_config = %AggregateConfig{
      id: "agg-12345",
      handler: Handler,
      registry: nil,
      supervisor: nil,
      event_store: nil,
      aggregate_state: %MyState{name: "James", age: 23},
      aggregate_number: 0
    }

    assert {:ok, %MyState{name: "James", age: 23}} ==
             Headwater.AggregateDirectory.Result.new({:ok, aggregate_config})
  end

  test "returns business logic error when next_state/2 fails" do
    assert {:error, :not_enough_sass} ==
             Headwater.AggregateDirectory.Result.new(
               {:error, :next_state, {:error, :not_enough_sass}}
             )
  end

  test "returns business logic error when execute/2 fails" do
    assert {:error, :too_much_sass} ==
             Headwater.AggregateDirectory.Result.new({:error, :execute, {:error, :too_much_sass}})
  end
end

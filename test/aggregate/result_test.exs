defmodule Headwater.Aggregate.Directory.ResultTest do
  use ExUnit.Case
  alias Headwater.Aggregate.AggregateConfig

  defmodule MyState do
    defstruct [:name, :age]
  end

  test "when the aggregate is empty" do
    aggregate_state = nil

    assert {:warn, :empty_aggregate} ==
             Headwater.Aggregate.Directory.Result.new({:ok, aggregate_state})
  end

  test "when aggregate has state" do
    aggregate_state = %MyState{name: "James", age: 23}

    assert {:ok, %MyState{name: "James", age: 23}} ==
             Headwater.Aggregate.Directory.Result.new({:ok, aggregate_state})
  end

  test "returns business logic error when next_state/2 fails" do
    assert {:error, :not_enough_sass} ==
             Headwater.Aggregate.Directory.Result.new(
               {:error, :next_state, {:error, :not_enough_sass}}
             )
  end

  test "returns business logic error when execute/2 fails" do
    assert {:error, :too_much_sass} ==
             Headwater.Aggregate.Directory.Result.new(
               {:error, :execute, {:error, :too_much_sass}}
             )
  end
end

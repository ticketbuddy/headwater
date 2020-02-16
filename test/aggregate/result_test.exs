defmodule Headwater.AggregateDirectory.ResultTest do
  use ExUnit.Case

  defmodule MyState do
    defstruct [:name, :age]
  end

  test "encodes the output" do
    output = %Headwater.AggregateDirectory.Result{
      event_id: 1,
      state: %MyState{name: "James", age: 23},
      aggregate_id: "user-1"
    }

    assert {:ok, ~s({"age":23,"name":"James"})} == Jason.encode(output)
  end

  test "when the aggregate is empty" do
    latest_event_id = 0
    state = nil
    aggregate_id = "agg-12345"

    assert {:warn,
            {:empty_aggregate,
             %Headwater.AggregateDirectory.Result{
               event_id: 0,
               state: nil,
               aggregate_id: "agg-12345"
             }}} ==
             Headwater.AggregateDirectory.Result.new(
               {:ok, {latest_event_id, state}},
               aggregate_id
             )
  end

  test "returns business logic error when next_state/2 fails" do
    aggregate_id = "agg-12345"

    assert {:error, :not_enough_sass} ==
             Headwater.AggregateDirectory.Result.new(
               {:error, :next_state, {:error, :not_enough_sass}},
               aggregate_id
             )
  end

  test "returns business logic error when execute/2 fails" do
    aggregate_id = "agg-12345"

    assert {:error, :too_much_sass} ==
             Headwater.AggregateDirectory.Result.new(
               {:error, :execute, {:error, :too_much_sass}},
               aggregate_id
             )
  end
end

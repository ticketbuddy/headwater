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
end

defmodule ExampleTest do
  use ExUnit.Case
  doctest Example

  test "greets the world" do
    assert {} == Example.inc(%Example.Increment{counter_id: "abc", increment_by: 5})
  end
end

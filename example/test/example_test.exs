defmodule ExampleTest do
  use ExUnit.Case
  use Headwater.TestHelper, event_store_repo: Example.Repo

  test "increments a counter and returns the state in an :ok tuple" do
    assert {:ok, %Example.Counter{total: 5}} ==
             Example.inc(%Example.Increment{counter_id: "abc", increment_by: 5})
  end
end

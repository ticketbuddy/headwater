defmodule ExampleTest do
  use ExUnit.Case
  use Example.Test.Support.Helper, :persist

  test "increments & reads a counter" do
    assert {:ok,
            %Headwater.Aggregate.Result{
              state: %Example.Counter{total: 1},
              latest_event_id: 1
            }} == Example.inc(%Example.Increment{counter_id: "first-counter", increment_by: 1})

    assert {:ok,
            %Headwater.Aggregate.Result{
              state: %Example.Counter{total: 3},
              latest_event_id: 1
            }} ==
             Example.inc(%Example.Increment{counter_id: "a-counter", increment_by: 3})

    assert {:ok,
            %Headwater.Aggregate.Result{
              state: %Example.Counter{total: 6},
              latest_event_id: 2
            }} ==
             Example.inc(%Example.Increment{counter_id: "first-counter", increment_by: 5})

    assert {:ok,
            %Headwater.Aggregate.Result{
              state: %Example.Counter{total: 6},
              latest_event_id: 2
            }} == Example.read_counter("first-counter")
  end
end

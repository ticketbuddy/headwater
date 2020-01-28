defmodule ExampleTest do
  use ExUnit.Case
  use Example.Test.Support.Helper, :persist

  test "increments & reads a counter" do
    assert {:ok,
            %HeadwaterSpring.Result{
              state: %Example.Counter{total: 1},
              latest_event_id: 1
            }} == Example.inc(%Example.IncrementCounter{id: "first-counter", qty: 1})

    assert {:ok,
            %HeadwaterSpring.Result{
              state: %Example.Counter{total: 3},
              latest_event_id: 1
            }} ==
             Example.inc(%Example.IncrementCounter{id: "a-counter", qty: 3})

    assert {:ok,
            %HeadwaterSpring.Result{
              state: %Example.Counter{total: 6},
              latest_event_id: 2
            }} ==
             Example.inc(%Example.IncrementCounter{id: "first-counter", qty: 5})

    assert {:ok,
            %HeadwaterSpring.Result{
              state: %Example.Counter{total: 6},
              latest_event_id: 2
            }} == Example.read_counter("first-counter")
  end
end

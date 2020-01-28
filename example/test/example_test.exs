defmodule ExampleTest do
  use ExUnit.Case
  use Example.Test.Support.Helper, :persist

  test "increments & reads a counter" do
    assert {:ok,
            %HeadwaterSpring.Result{
              state: %Example.Counter{total: 1}
            }} == Example.inc(%Example.IncrementCounter{id: "first-counter", qty: 1})

    # assert {:ok, %Example.Counter{total: 3}} ==
    #          Example.inc(%Example.IncrementCounter{id: "a-counter", qty: 1})
    #
    # assert {:ok, %Example.Counter{total: 5}} ==
    #          Example.inc(%Example.IncrementCounter{id: "a-second-counter", qty: 5})
    #
    # assert {:ok, %Example.Counter{total: 4}} == Example.read_counter("a-counter")
  end
end

defmodule ExampleTest do
  use ExUnit.Case
  use Example.Test.Support.Helper, :persist

  test "increments & reads a counter" do
    assert {:ok,
            %Headwater.AggregateDirectory.Result{
              state: %Example.Counter{total: 1},
              event_id: 1,
              aggregate_id: "first-counter",
              event_ref: _event_ref
            }} = Example.inc(%Example.Increment{counter_id: "first-counter", increment_by: 1})

    assert {:ok,
            %Headwater.AggregateDirectory.Result{
              state: %Example.Counter{total: 3},
              event_id: 1,
              aggregate_id: "a-counter",
              event_ref: _event_ref
            }} = Example.inc(%Example.Increment{counter_id: "a-counter", increment_by: 3})

    assert {:ok,
            %Headwater.AggregateDirectory.Result{
              state: %Example.Counter{total: 6},
              event_id: 2,
              aggregate_id: "first-counter",
              event_ref: _event_ref
            }} = Example.inc(%Example.Increment{counter_id: "first-counter", increment_by: 5})

    assert {:ok,
            %Headwater.AggregateDirectory.Result{
              state: %Example.Counter{total: 6},
              event_id: 2,
              aggregate_id: "first-counter",
              event_ref: _event_ref
            }} = Example.read_counter("first-counter")
  end

  test "asks for a wish, that returns two events" do
    assert {:ok,
            %Headwater.AggregateDirectory.Result{
              state: %Example.Counter{total: 8},
              event_id: 2,
              aggregate_id: "first-multi-counter",
              event_ref: _event_ref
            }} =
             Example.inc(%Example.MultiIncrement{
               counter_id: "first-multi-counter",
               increment_by: 5,
               increment_again: 3
             })
  end

  test "when subsequent wishes have used idempotency key" do
    idempotency_key = "idempo-12345"

    assert {:ok,
            %Headwater.AggregateDirectory.Result{
              aggregate_id: "idempotent-counter",
              event_id: 1,
              state: %Example.Counter{total: 1},
              event_ref: _event_ref
            }} =
             Example.inc(%Example.Increment{counter_id: "idempotent-counter", increment_by: 1},
               idempotency_key: idempotency_key
             )

    assert {:ok,
            %Headwater.AggregateDirectory.Result{
              aggregate_id: "idempotent-counter",
              event_id: 1,
              state: %Example.Counter{total: 1},
              event_ref: _event_ref
            }} =
             Example.inc(%Example.Increment{counter_id: "idempotent-counter", increment_by: 1},
               idempotency_key: idempotency_key
             )
  end
end

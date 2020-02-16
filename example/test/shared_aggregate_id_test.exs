defmodule Example.AggregateIdTest do
  use ExUnit.Case

  use Example.Test.Support.Helper, :persist

  describe "action" do
    test "shared aggregate ID keeps aggregates separate" do
      shared_aggregate_id = "aggregate-id-one"

      assert {:ok,
              %Headwater.AggregateDirectory.Result{
                state: %Example.Counter{total: 1},
                event_id: 1,
                event_ref: _event_ref,
                aggregate_id: shared_aggregate_id
              }} =
               Example.inc(%Example.Increment{counter_id: shared_aggregate_id, increment_by: 1})

      assert {:ok,
              %Headwater.AggregateDirectory.Result{
                state: %Example.Reducer{total: -1, counter_id: shared_aggregate_id},
                event_id: 1,
                aggregate_id: "reducer_" <> shared_aggregate_id,
                event_ref: _event_ref
              }} = Example.reduce(%Example.Reduce{counter_id: shared_aggregate_id, reduce_by: 1})
    end
  end

  describe "read" do
    test "shared aggregate ID keeps aggregates separate" do
      shared_aggregate_id = "aggregate-id-two"

      Example.inc(%Example.Increment{counter_id: shared_aggregate_id, increment_by: 1})
      Example.reduce(%Example.Reduce{counter_id: shared_aggregate_id, reduce_by: 1})

      assert {:ok,
              %Headwater.AggregateDirectory.Result{
                aggregate_id: "aggregate-id-two",
                event_id: 1,
                state: %Example.Counter{total: 1},
                event_ref: _event_ref
              }} = Example.read_counter(shared_aggregate_id)

      assert {:ok,
              %Headwater.AggregateDirectory.Result{
                aggregate_id: "reducer_aggregate-id-two",
                event_id: 1,
                state: %Example.Reducer{counter_id: "aggregate-id-two", total: -1},
                event_ref: _event_ref
              }} = Example.read_reducer(shared_aggregate_id)
    end
  end
end

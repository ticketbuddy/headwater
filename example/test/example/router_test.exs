defmodule Example.RouterTest do
  use ExUnit.Case
  use Headwater.TestHelper, repo: Example.Repo

  test "increments a counter and returns the state in an :ok tuple" do
    assert {:ok, %Example.Counter{total: 5}} ==
             Example.Router.handle(%Example.Increment{
               counter_id: "counter_8790ce86756844c18e6ac51708524e7e",
               increment_by: 5
             })
  end

  test "idempotent requests return same state" do
    idempotency = "idempo-4535"
    expected_state = %Example.Counter{total: 5}

    assert {:ok, expected_state} ==
             Example.Router.handle(
               %Example.Increment{
                 counter_id: "counter_idempoidempoidempoidempoidempo7e",
                 increment_by: 5
               },
               idempotency_key: idempotency
             )

    assert {:ok, expected_state} ==
             Example.Router.handle(
               %Example.Increment{
                 counter_id: "counter_idempoidempoidempoidempoidempo7e",
                 increment_by: 5
               },
               idempotency_key: idempotency
             )

    assert {:ok, expected_state} ==
             Example.Router.handle(
               %Example.Increment{
                 counter_id: "counter_idempoidempoidempoidempoidempo7e",
                 increment_by: 5
               },
               idempotency_key: idempotency
             )
  end

  test "when counter is empty" do
    assert {:warn, :empty_aggregate} ==
             Example.Router.read_counter("a-nothing-counter")
  end

  test "loads state of aggregate when number of events for the aggregate is above the batch read size" do
    assert {:ok, %Example.Counter{total: 17500}} == Example.Router.read_counter("many-events")
  end
end

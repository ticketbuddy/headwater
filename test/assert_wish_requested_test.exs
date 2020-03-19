defmodule Headwater.TestSupport.AggregateDirectoryTest do
  use ExUnit.Case

  import Headwater.TestSupport.AggregateDirectory,
    only: [
      set_read_state_result: 1,
      set_handle_result: 1,
      assert_wish_requested: 1,
      assert_state_requested: 1
    ]

  test "can assert that a wish has been submitted" do
    FakeApp.Router.handle(%FakeApp.ScorePoint{})

    assert_wish_requested(%Headwater.AggregateDirectory.WriteRequest{
      aggregate_id: "game-one",
      handler: FakeApp,
      idempotency_key: _idempo,
      wish: %FakeApp.ScorePoint{game_id: "game-one", value: 1}
    })
  end

  test "can assert that a state has been requested" do
    FakeApp.Router.get_score("game-one")

    assert_state_requested(%Headwater.AggregateDirectory.ReadRequest{
      aggregate_id: "game-one",
      handler: FakeApp
    })
  end

  test "can stub the result (read)" do
    set_read_state_result({:error, :a_read_reason})
    assert {:error, :a_read_reason} == FakeApp.Router.get_score("game-one")

    # clears the return value
    assert is_nil(Process.get(:_headwater_read_state_result))

    # goes back to default
    assert {:ok, "aggregate state stubbed"} == FakeApp.Router.handle(%FakeApp.ScorePoint{})
  end

  test "can stub the result (action)" do
    set_handle_result({:error, :a_reason})
    assert {:error, :a_reason} == FakeApp.Router.handle(%FakeApp.ScorePoint{})

    # clears the return value
    assert is_nil(Process.get(:_headwater_handle_result))

    # goes back to default
    assert {:ok, "aggregate state stubbed"} == FakeApp.Router.handle(%FakeApp.ScorePoint{})
  end
end

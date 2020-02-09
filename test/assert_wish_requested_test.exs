defmodule Headwater.TestSupport.AggregateDirectoryTest do
  use ExUnit.Case

  import Headwater.TestSupport.AggregateDirectory,
    only: [set_handle_result: 1, assert_wish_requested: 1]

  alias Headwater.AggregateDirectory.Result

  test "can assert that a wish has been submitted" do
    FakeApp.Router.score(%FakeApp.ScorePoint{})

    assert_wish_requested(%Headwater.AggregateDirectory.WriteRequest{
      aggregate_id: "game-one",
      handler: FakeApp,
      idempotency_key: _idempo,
      wish: %FakeApp.ScorePoint{game_id: "game-one", value: 1}
    })
  end

  test "can stub the result" do
    set_handle_result({:error, :a_reason})
    assert {:error, :a_reason} == FakeApp.Router.score(%FakeApp.ScorePoint{})

    # clears the return value
    assert is_nil(Process.get(:_headwater_handle_result))

    # goes back to default
    assert {:ok, %Result{}} == FakeApp.Router.score(%FakeApp.ScorePoint{})
  end
end

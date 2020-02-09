defmodule Headwater.TestSupport.AggregateDirectoryTest do
  use ExUnit.Case
  import Headwater.TestSupport.AggregateDirectory, only: [assert_wish_requested: 1]

  test "can assert that a wish has been submitted" do
    FakeApp.Router.score(%FakeApp.ScorePoint{})

    assert_wish_requested(%Headwater.AggregateDirectory.WriteRequest{
      aggregate_id: "game-one",
      handler: FakeApp,
      idempotency_key: _idempo,
      wish: %FakeApp.ScorePoint{game_id: "game-one", value: 1}
    })
  end
end

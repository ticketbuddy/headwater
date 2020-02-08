defmodule HeadwaterSpring.RouterTest do
  use ExUnit.Case

  import Mox
  setup :set_mox_global
  setup :verify_on_exit!

  defmodule FakeRouter do
    use HeadwaterSpring.Router, spring: HeadwaterSpringMock

    defaction(:score, to: FakeApp, by_key: :game_id)
    defread(:read_points, to: FakeApp)
  end

  test "handles an action" do
    HeadwaterSpringMock
    |> expect(:handle, fn %HeadwaterSpring.WriteRequest{
                            handler: FakeApp,
                            idempotency_key: _a_random_value,
                            stream_id: "game-one",
                            wish: %FakeApp.ScorePoint{game_id: "game-one", value: 1}
                          } ->
      {:ok,
       %HeadwaterSpring.Result{
         latest_event_id: 1,
         state: %FakeApp{}
       }}
    end)

    assert {:ok,
            %HeadwaterSpring.Result{
              latest_event_id: 1,
              state: %FakeApp{}
            }} == FakeRouter.score(%FakeApp.ScorePoint{})
  end

  test "uses the provided idempotency_key" do
    HeadwaterSpringMock
    |> expect(:handle, fn %HeadwaterSpring.WriteRequest{
                            idempotency_key: "idem-po-54321"
                          } ->
      {:ok,
       %HeadwaterSpring.Result{
         latest_event_id: 1,
         state: %FakeApp{}
       }}
    end)

    assert {:ok,
            %HeadwaterSpring.Result{
              latest_event_id: 1,
              state: %FakeApp{}
            }} == FakeRouter.score(%FakeApp.ScorePoint{}, idempotency_key: "idem-po-54321")
  end
end

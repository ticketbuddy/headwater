defmodule Headwater.Spring.RouterTest do
  use ExUnit.Case

  import Mox
  setup :set_mox_global
  setup :verify_on_exit!

  defmodule FakeRouter do
    use Headwater.Spring.Router, spring: Headwater.SpringMock

    defaction(:score, to: FakeApp, by_key: :game_id)
    defread(:read_points, to: FakeApp)
  end

  test "handles an action" do
    Headwater.SpringMock
    |> expect(:handle, fn %Headwater.Spring.WriteRequest{
                            handler: FakeApp,
                            idempotency_key: _a_random_value,
                            stream_id: "game-one",
                            wish: %FakeApp.ScorePoint{game_id: "game-one", value: 1}
                          } ->
      {:ok,
       %Headwater.Spring.Result{
         latest_event_id: 1,
         state: %FakeApp{}
       }}
    end)

    assert {:ok,
            %Headwater.Spring.Result{
              latest_event_id: 1,
              state: %FakeApp{}
            }} == FakeRouter.score(%FakeApp.ScorePoint{})
  end

  test "uses the provided idempotency_key" do
    Headwater.SpringMock
    |> expect(:handle, fn %Headwater.Spring.WriteRequest{
                            idempotency_key: "idem-po-54321"
                          } ->
      {:ok,
       %Headwater.Spring.Result{
         latest_event_id: 1,
         state: %FakeApp{}
       }}
    end)

    assert {:ok,
            %Headwater.Spring.Result{
              latest_event_id: 1,
              state: %FakeApp{}
            }} == FakeRouter.score(%FakeApp.ScorePoint{}, idempotency_key: "idem-po-54321")
  end

  test "retrieves the current state" do
    Headwater.SpringMock
    |> expect(:read_state, fn %Headwater.Spring.ReadRequest{
                                handler: FakeApp,
                                stream_id: "game-one"
                              } ->
      {:ok,
       %Headwater.Spring.Result{
         latest_event_id: 1,
         state: %FakeApp{}
       }}
    end)

    assert {:ok,
            %Headwater.Spring.Result{
              latest_event_id: 1,
              state: %FakeApp{}
            }} == FakeRouter.read_points("game-one")
  end
end

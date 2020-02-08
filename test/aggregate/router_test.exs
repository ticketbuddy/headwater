defmodule Headwater.Aggregate.RouterTest do
  use ExUnit.Case

  import Mox
  setup :set_mox_global
  setup :verify_on_exit!

  defmodule FakeRouter do
    use Headwater.Aggregate.Router, aggregate: Headwater.AggregateMock

    defaction(:score, to: FakeApp, by_key: :game_id)
    defread(:read_points, to: FakeApp)
  end

  test "handles an action" do
    Headwater.AggregateMock
    |> expect(:handle, fn %Headwater.AggregateDirectory.WriteRequest{
                            handler: FakeApp,
                            idempotency_key: _a_random_value,
                            aggregate_id: "game-one",
                            wish: %FakeApp.ScorePoint{game_id: "game-one", value: 1}
                          } ->
      {:ok,
       %Headwater.AggregateDirectory.Result{
         latest_event_id: 1,
         state: %FakeApp{}
       }}
    end)

    assert {:ok,
            %Headwater.AggregateDirectory.Result{
              latest_event_id: 1,
              state: %FakeApp{}
            }} == FakeRouter.score(%FakeApp.ScorePoint{})
  end

  test "uses the provided idempotency_key" do
    Headwater.AggregateMock
    |> expect(:handle, fn %Headwater.AggregateDirectory.WriteRequest{
                            idempotency_key: "idem-po-54321"
                          } ->
      {:ok,
       %Headwater.AggregateDirectory.Result{
         latest_event_id: 1,
         state: %FakeApp{}
       }}
    end)

    assert {:ok,
            %Headwater.AggregateDirectory.Result{
              latest_event_id: 1,
              state: %FakeApp{}
            }} == FakeRouter.score(%FakeApp.ScorePoint{}, idempotency_key: "idem-po-54321")
  end

  test "retrieves the current state" do
    Headwater.AggregateMock
    |> expect(:read_state, fn %Headwater.AggregateDirectory.ReadRequest{
                                handler: FakeApp,
                                aggregate_id: "game-one"
                              } ->
      {:ok,
       %Headwater.AggregateDirectory.Result{
         latest_event_id: 1,
         state: %FakeApp{}
       }}
    end)

    assert {:ok,
            %Headwater.AggregateDirectory.Result{
              latest_event_id: 1,
              state: %FakeApp{}
            }} == FakeRouter.read_points("game-one")
  end
end

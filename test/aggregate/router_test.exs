defmodule Headwater.Aggregate.RouterTest do
  use ExUnit.Case

  import Mox
  setup :set_mox_global
  setup :verify_on_exit!

  test "returns error when id is invalid" do
    assert {:warn, :invalid_id} == FakeApp.handle(%FakeApp.ScoreTwoPoints{game_id: "invalid-id"})
  end

  test "calls directory to submit a wish to an aggregate" do
    Headwater.Aggregate.DirectoryMock
    |> expect(:handle, fn %Headwater.Aggregate.Directory.WriteRequest{
                            aggregate_id: "game_8790ce86756844c18e6ac51708524e7e",
                            handler: FakeApp.Game,
                            idempotency_key: _idempotency_key,
                            wish: %FakeApp.ScoreTwoPoints{
                              game_id: "game_8790ce86756844c18e6ac51708524e7e",
                              value: 1
                            }
                          },
                          %Headwater.Config{} ->
      {:ok, %FakeApp.Game{}}
    end)

    assert {:ok, %FakeApp.Game{}} == FakeApp.handle(%FakeApp.ScoreTwoPoints{})
  end

  test "uses the provided idempotency_key" do
    Headwater.Aggregate.DirectoryMock
    |> expect(:handle, fn %Headwater.Aggregate.Directory.WriteRequest{
                            idempotency_key: "idem-po-54321"
                          },
                          %Headwater.Config{} ->
      {:ok, %FakeApp.Game{}}
    end)

    assert {:ok, %FakeApp.Game{}} ==
             FakeApp.handle(%FakeApp.ScoreTwoPoints{}, idempotency_key: "idem-po-54321")
  end

  test "calls directory to read state of aggregate" do
    Headwater.Aggregate.DirectoryMock
    |> expect(:handle, fn %Headwater.Aggregate.Directory.ReadRequest{
                            handler: FakeApp.Game,
                            aggregate_id: "game_8790ce86756844c18e6ac51708524e7e"
                          },
                          %Headwater.Config{} ->
      {:ok, %FakeApp.Game{}}
    end)

    assert {:ok, %FakeApp.Game{}} == FakeApp.get_score("game_8790ce86756844c18e6ac51708524e7e")
  end
end

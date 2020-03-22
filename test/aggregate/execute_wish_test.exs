defmodule Headwater.Aggregate.ExecuteWishTest do
  use ExUnit.Case

  alias Headwater.Aggregate.{ExecuteWish, AggregateConfig}
  alias Headwater.Aggregate.Directory.WriteRequest

  defmodule Wish do
    defstruct value: 3
  end

  defmodule Event do
    defstruct value: 3
  end

  defmodule Handler do
    def execute(state, wish) do
      {:ok, [%Event{value: state + wish.value}, %Event{value: state * wish.value}]}
    end
  end

  defmodule HandlerWithError do
    def execute(_state, _wish) do
      {:error, :not_enough_lemonade}
    end
  end

  describe "process/2" do
    test "increments aggregate number" do
      aggregate_config = %AggregateConfig{
        id: "abc-123",
        handler: Handler,
        registry: nil,
        supervisor: nil,
        event_store: nil,
        aggregate_state: 5,
        aggregate_number: 37
      }

      write_request = %WriteRequest{
        wish: %Wish{},
        aggregate_id: "abc-123",
        handler: Handler,
        idempotency_key: "idempo-1334"
      }

      assert {:ok,
              {%Headwater.Aggregate.AggregateConfig{
                 aggregate_state: 5,
                 handler: Headwater.Aggregate.ExecuteWishTest.Handler,
                 id: "abc-123",
                 aggregate_number: 39
               },
               [
                 %Headwater.EventStore.PersistEvent{
                   aggregate_id: "abc-123",
                   aggregate_number: 38,
                   data:
                     "{\"__struct__\":\"Elixir.Headwater.Aggregate.ExecuteWishTest.Event\",\"value\":8}"
                 },
                 %Headwater.EventStore.PersistEvent{
                   aggregate_id: "abc-123",
                   aggregate_number: 39,
                   data:
                     "{\"__struct__\":\"Elixir.Headwater.Aggregate.ExecuteWishTest.Event\",\"value\":15}"
                 }
               ]}} = ExecuteWish.process(aggregate_config, write_request)
    end

    test "when execute returns an error" do
      aggregate_config = %AggregateConfig{
        id: "abc-123",
        handler: HandlerWithError,
        registry: nil,
        supervisor: nil,
        event_store: nil,
        aggregate_state: 5,
        aggregate_number: 37
      }

      write_request = %WriteRequest{
        wish: %Wish{},
        aggregate_id: "abc-123",
        handler: HandlerWithError,
        idempotency_key: "idempo-1334"
      }

      assert {:error, :execute, {:error, :not_enough_lemonade}} ==
               ExecuteWish.process(aggregate_config, write_request)
    end
  end
end

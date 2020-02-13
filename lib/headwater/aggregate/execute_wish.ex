defmodule Headwater.Aggregate.ExecuteWish do
  def process(aggregate, aggregate_state, wish) do
    case aggregate.handler.execute(aggregate_state, wish) do
      {:ok, event} -> {:ok, List.wrap(event)}
      result -> {:error, :execute, result}
    end
  end
end

defmodule Headwater.Aggregate.ExecuteWish do
  def process(aggregate, aggregate_state, wish) do
    require Logger
    Logger.log(:info, "#{aggregate.handler}.execute/2 for wish #{wish.__struct__}")

    case aggregate.handler.execute(aggregate_state, wish) do
      {:ok, event} -> {:ok, List.wrap(event)}
      result -> {:error, :execute, result}
    end
  end
end

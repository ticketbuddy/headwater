defmodule Headwater.Aggregate.NextState do
  def process(_aggregate, aggregate_state, []) do
    {:ok, aggregate_state}
  end

  def process(aggregate, aggregate_state, [new_event | next_events]) do
    require Logger
    Logger.log(:info, "#{aggregate.handler}.next_state/2 for #{new_event.__struct__}")

    case aggregate.handler.next_state(aggregate_state, new_event) do
      response = {:error, reason} ->
        {:error, :next_state, response}

      new_aggregate_state ->
        process(aggregate, new_aggregate_state, next_events)
    end
  end
end

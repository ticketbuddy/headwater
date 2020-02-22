defmodule Headwater.Aggregate.NextState do
  alias Headwater.Aggregate.AggregateConfig

  def process(aggregate_config, []) do
    {:ok, aggregate_config}
  end

  def process(
        aggregate_config = %AggregateConfig{handler: handler, aggregate_state: aggregate_state},
        [new_event | next_events]
      ) do
    case handler.next_state(aggregate_state, new_event.data) do
      response = {:error, _reason} ->
        {:error, :next_state, response}

      new_aggregate_state ->
        AggregateConfig.set_aggregate_state(aggregate_config, new_aggregate_state)
        |> process(next_events)
    end
  end
end

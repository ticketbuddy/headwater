defmodule Headwater.Aggregate.NextState do
  alias Headwater.Aggregate.{AggregateConfig, Idempotency}

  def process(aggregate_config, []) do
    {:ok, aggregate_config}
  end

  def process(
        aggregate_config = %AggregateConfig{handler: handler, aggregate_state: aggregate_state},
        [recorded_event | recorded_events]
      ) do
    case handler.next_state(aggregate_state, recorded_event.data) do
      response = {:error, _reason} ->
        {:error, :next_state, response}

      new_aggregate_state ->
        aggregate_config
        |> Idempotency.store(recorded_event.idempotency_key)
        |> AggregateConfig.set_aggregate_state(new_aggregate_state)
        |> AggregateConfig.update_aggregate_number(recorded_event)
        |> process(recorded_events)
    end
  end
end

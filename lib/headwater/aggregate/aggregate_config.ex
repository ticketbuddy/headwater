defmodule Headwater.Aggregate.AggregateConfig do
  @moduledoc """
  Struct to contain the config for an aggregate.
  """
  @enforce_keys [
    :id,
    :handler,
    :registry,
    :supervisor,
    :event_store,
    :aggregate_state
  ]

  defstruct @enforce_keys ++ [aggregate_number: 0]

  def inc_aggregate_number(aggregate_config) do
    Map.update(aggregate_config, :aggregate_number, 0, &(&1 + 1))
  end

  def update_aggregate_number(aggregate_config, recorded_event) do
    Map.put(aggregate_config, :aggregate_number, recorded_event.aggregate_number)
  end

  def set_aggregate_state(aggregate_config, new_state) do
    Map.put(aggregate_config, :aggregate_state, new_state)
  end
end

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
    :aggregate_state,
    aggregate_number: 0
  ]

  defstruct @enforce_keys

  def inc_aggregate_number(aggregate_config, count) do
    Map.update(aggregate_config, :aggregate_number, 0, &(&1 + count))
  end
end

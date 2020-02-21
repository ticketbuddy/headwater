defmodule Headwater.Aggregate.ExecuteWish do
  # TODO: convert the returned events, into `Headwater.EventStore.PersistEvent`
  # types

  alias Headwater.EventStore.PersistEvent
  alias Headwater.Aggregate.AggregateConfig

  def process(
        aggregate_config = %AggregateConfig{handler: handler, aggregate_state: aggregate_state},
        wish
      ) do
    aggregate_state
    |> handler.execute(wish)
    |> format_result(aggregate_config)
  end

  defp format_result({:ok, events}, aggregate_config) do
    start_values = {aggregate_config, []}

    result =
      List.wrap(events)
      |> Enum.reduce(start_values, fn event, acc ->
        {aggregate_config, persisted_events} = acc
        aggregate_config = AggregateConfig.inc_aggregate_number(aggregate_config)
        persisted_event = PersistEvent.new(event, aggregate_config)

        {aggregate_config, persisted_events ++ [persisted_event]}
      end)

    {:ok, result}
  end

  defp format_result(error_result, _aggregate_config) do
    {:error, :execute, error_result}
  end
end

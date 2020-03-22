defmodule Headwater.Aggregate.ExecuteWish do
  # TODO: convert the returned events, into `Headwater.EventStore.PersistEvent`
  # types

  alias Headwater.EventStore.PersistEvent
  alias Headwater.Aggregate.AggregateConfig
  alias Headwater.Aggregate.Directory.WriteRequest

  def process(
        aggregate_config = %AggregateConfig{handler: handler, aggregate_state: aggregate_state},
        write_request = %WriteRequest{}
      ) do
    aggregate_state
    |> handler.execute(write_request.wish)
    |> format_result(aggregate_config, write_request)
  end

  defp format_result({:ok, events}, aggregate_config, write_request) do
    start_values = {aggregate_config, []}

    result =
      List.wrap(events)
      |> Enum.reduce(start_values, fn event, acc ->
        {aggregate_config, persisted_events} = acc
        aggregate_config = AggregateConfig.inc_aggregate_number(aggregate_config)
        persisted_event = PersistEvent.new(event, aggregate_config, write_request)

        {aggregate_config, persisted_events ++ [persisted_event]}
      end)

    {:ok, result}
  end

  defp format_result(error_result, _aggregate_config, _write_request) do
    {:error, :execute, error_result}
  end
end

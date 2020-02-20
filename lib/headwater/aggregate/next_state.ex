defmodule Headwater.Aggregate.NextState do
  def process(_handler, aggregate_state, [], aggregate_number) do
    {:ok, aggregate_state, aggregate_number}
  end

  def process(handler, aggregate_state, [new_event | next_events], aggregate_number \\ nil) do
    case handler.next_state(aggregate_state, new_event.data) do
      response = {:error, reason} ->
        {:error, :next_state, response}

      new_aggregate_state ->
        process(handler, new_aggregate_state, next_events, new_event.aggregate_number)
    end
  end
end

defmodule Headwater.EventStore.Adapters.Postgres.ReadStream do
  def read(callback, base_count) do
    Elixir.Stream.resource(
      fn -> base_count end,
      fn next_event_count ->
        case callback.(next_event_count) do
          {:ok, []} ->
            {:halt, next_event_count}

          {:ok, events} ->
            {events, next_event_count + length(events)}
        end
      end,
      fn _ -> :ok end
    )
  end
end

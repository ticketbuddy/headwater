defmodule Headwater.EventStore.Adapters.Postgres.ReadStream do
  def read(callback, opts) do
    {from_event_number, opts} = Keyword.pop(opts, :starting_event_number, 0)

    Elixir.Stream.resource(
      fn -> from_event_number end,
      fn next_event_number ->
        case callback.(next_event_number) do
          {:ok, []} -> {:halt, next_event_number}
          {:ok, events} -> {events, next_event_number + length(events)}
        end
      end,
      fn _ -> :ok end
    )
  end
end

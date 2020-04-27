defmodule Headwater.EventStore.Adapters.Postgres.Query do
  import Ecto.Query, only: [from: 2]
  @default_batch_read_size 100

  alias Headwater.EventStore.Adapters.Postgres.{
    HeadwaterEventsSchema,
    HeadwaterEventBusSchema
  }

  def recorded_events(opts) do
    {from_event_number, opts} = Keyword.pop(opts, :from_event_number, 0)
    {read_batch_size, opts} = Keyword.pop(opts, :read_batch, @default_batch_read_size)

    from(event in HeadwaterEventsSchema,
      where: event.event_number > ^from_event_number,
      order_by: [asc: event.event_number],
      limit: ^read_batch_size
    )
  end

  def recorded_events(aggregate_id, opts) do
    {from_aggregate_number, opts} = Keyword.pop(opts, :from_aggregate_number, 0)
    {read_batch_size, opts} = Keyword.pop(opts, :read_batch, @default_batch_read_size)

    from(event in HeadwaterEventsSchema,
      where:
        event.aggregate_id == ^aggregate_id and event.aggregate_number > ^from_aggregate_number,
      order_by: [asc: event.event_number],
      limit: ^read_batch_size
    )
  end

  def event_bus_next_event_number(bus_id) do
    from(event in HeadwaterEventBusSchema,
      where: event.bus_id == ^bus_id,
      order_by: [desc: event.event_ref],
      limit: ^1
    )
  end
end

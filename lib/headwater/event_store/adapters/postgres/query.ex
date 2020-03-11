defmodule Headwater.EventStore.Adapters.Postgres.Query do
  import Ecto.Query, only: [from: 2]
  @default_batch_read_size 100

  alias Headwater.EventStore.Adapters.Postgres.{
    HeadwaterEventsSchema,
    HeadwaterEventBusSchema
  }

  def next_recorded_events_for_listener(bus_id, opts) do
    # TODO: can an SQL query determine which recorded events
    # a listener has not yet played

    {from_event_number, opts} = Keyword.pop(opts, :from_event_number, 0)
    {read_batch_size, opts} = Keyword.pop(opts, :read_batch, @default_batch_read_size)

    from(event in HeadwaterEventsSchema,
      left_join: event_bus in HeadwaterEventBusSchema,
      on: event_bus.event_ref == event.event_number,
      where: event.event_number > ^from_event_number,
      # where: event_bus.bus_id == ^bus_id,
      order_by: [asc: event.event_number],
      limit: ^read_batch_size
    )
  end

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
    {from_event_number, opts} = Keyword.pop(opts, :from_event_number, 0)
    {read_batch_size, opts} = Keyword.pop(opts, :read_batch, @default_batch_read_size)

    from(event in HeadwaterEventsSchema,
      where: event.aggregate_id == ^aggregate_id and event.event_number > ^from_event_number,
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

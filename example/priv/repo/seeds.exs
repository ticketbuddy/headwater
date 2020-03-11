alias Headwater.EventStore.Adapters.Postgres.{HeadwaterEventsSchema, HeadwaterEventBusSchema}

0..2500
|> Enum.each(fn index ->
  Example.Repo.insert!(%HeadwaterEventsSchema{
    aggregate_id: "many-events",
    aggregate_number: index,
    data: Headwater.EventStore.EventSerializer.serialize(%Example.Incremented{counter_id: "many-events", increment_by: 7}),
    event_id: UUID.uuid4(),
    idempotency_key: "2d9e90ea88524b45bd1988eb735ea2b4",
    inserted_at: ~U[2020-02-22 19:09:35Z],
    updated_at: ~U[2020-02-22 19:09:35Z]
  })
end)


0..5
|> Enum.each(fn index ->
  Example.Repo.insert!(%HeadwaterEventsSchema{
    aggregate_id: "not-so-many-events",
    aggregate_number: index,
    data: Headwater.EventStore.EventSerializer.serialize(%Example.Incremented{counter_id: "not-so-many-events", increment_by: 7}),
    event_id: UUID.uuid4(),
    idempotency_key: "bd19be94bb0ea88527e88a242d359e45",
    inserted_at: ~U[2020-02-22 19:09:35Z],
    updated_at: ~U[2020-02-22 19:09:35Z]
  })
end)

0..5
|> Enum.each(fn index ->
  Example.Repo.insert!(%HeadwaterEventBusSchema{
    bus_id: "big-red-bus",
    event_ref: index
  })
end)

IO.puts "seeds done..."

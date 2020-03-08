alias Headwater.EventStore.Adapters.Postgres.HeadwaterEventsSchema

0..2500
|> Enum.each(fn index ->
  Example.Repo.insert!(%HeadwaterEventsSchema{
    aggregate_id: "many-events",
    aggregate_number: index,
    data: Headwater.EventStore.EventSerializer.serialize(%Example.Incremented{counter_id: "many-events", increment_by: 7}),
    event_id: UUID.uuid4(),
    event_number: index,
    idempotency_key: "2d9e90ea88524b45bd1988eb735ea2b4",
    inserted_at: ~U[2020-02-22 19:09:35Z],
    updated_at: ~U[2020-02-22 19:09:35Z]
  })
end)

IO.puts "seeds done..."

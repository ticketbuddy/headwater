alias HeadwaterSpring.EventStoreAdapters.Postgres.{HeadwaterEventsSchema, HeadwaterEventBusSchema}

# Events
Example.Repo.insert!(%HeadwaterEventsSchema{
  event_id: 1,
  stream_id: "seeded-counter",
  idempotency_key: "f3e9ee81b8cd4283a40a4093b3ed551b",
  event:
    ~s({"__struct__":"Elixir.Example.Incremented","counter_id":"seeded-counter","increment_by":5})
})

Example.Repo.insert!(%HeadwaterEventsSchema{
  event_id: 1,
  stream_id: "a-different-seeded-counter",
  idempotency_key: "6a59a72f50b0436fbfb3ca031d71d235",
  event:
    ~s({"__struct__":"Elixir.Example.Incremented","counter_id":"seeded-counter","increment_by":32})
})

Example.Repo.insert!(%HeadwaterEventsSchema{
  event_id: 1,
  stream_id: "seeded-many-events-counter",
  idempotency_key: "fae7885a73c3452eb7eb99b176baf0e3",
  event:
    ~s({"__struct__":"Elixir.Example.Incremented","counter_id":"seeded-many-events-counter","increment_by":2})
})

Example.Repo.insert!(%HeadwaterEventsSchema{
  event_id: 2,
  stream_id: "seeded-many-events-counter",
  idempotency_key: "804ccbd800b34eb4b8586025cba5e95e",
  event:
    ~s({"__struct__":"Elixir.Example.Incremented","counter_id":"seeded-many-events-counter","increment_by":1})
})

Example.Repo.insert!(%HeadwaterEventsSchema{
  event_id: 1,
  stream_id: "event-ordering",
  idempotency_key: "721f402bf8c14db78dec82346bee9ab4",
  event:
    ~s({"__struct__":"Elixir.Example.Incremented","counter_id":"event-ordering","increment_by":10})
})

Example.Repo.insert!(%HeadwaterEventsSchema{
  event_id: 2,
  stream_id: "event-ordering",
  idempotency_key: "7ccdc378a8a64e979ea2d1e1af27b56d",
  event:
    ~s({"__struct__":"Elixir.Example.Incremented","counter_id":"event-ordering","increment_by":20})
})

# Event bus tracking

Example.Repo.insert!(%HeadwaterEventBusSchema{
  bus_id: "event_bus-one",
  event_ref: 15
})

IO.puts("Finished seed data.")

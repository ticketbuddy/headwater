alias Headwater.EventStoreAdapters.Postgres.{HeadwaterEventsSchema, HeadwaterEventBusSchema, HeadwaterIdempotencySchema}

# Events
Example.Repo.insert!(%HeadwaterEventsSchema{
  event_id: 1,
  aggregate_id: "seeded-counter",
  idempotency_id: "ed428506-b897-443a-b5f5-08492b921349",
  event:
    ~s({"__struct__":"Elixir.Example.Incremented","counter_id":"seeded-counter","increment_by":5})
})

Example.Repo.insert!(%HeadwaterEventsSchema{
  event_id: 1,
  aggregate_id: "a-different-seeded-counter",
  idempotency_id: "4ceeb017-bb5f-4cf2-a53b-c168500b89d7",
  event:
    ~s({"__struct__":"Elixir.Example.Incremented","counter_id":"seeded-counter","increment_by":32})
})

Example.Repo.insert!(%HeadwaterEventsSchema{
  event_id: 1,
  aggregate_id: "seeded-many-events-counter",
  idempotency_id: "63379329-faff-4f21-a48a-6d09034cf041",
  event:
    ~s({"__struct__":"Elixir.Example.Incremented","counter_id":"seeded-many-events-counter","increment_by":2})
})

Example.Repo.insert!(%HeadwaterEventsSchema{
  event_id: 2,
  aggregate_id: "seeded-many-events-counter",
  idempotency_id: "239dd70c-ddfb-4d11-a93d-3b2334a2b192",
  event:
    ~s({"__struct__":"Elixir.Example.Incremented","counter_id":"seeded-many-events-counter","increment_by":1})
})

Example.Repo.insert!(%HeadwaterEventsSchema{
  event_id: 1,
  aggregate_id: "event-ordering",
  idempotency_id: "d7425c16-62c7-4da9-acee-059acf6d641c",
  event:
    ~s({"__struct__":"Elixir.Example.Incremented","counter_id":"event-ordering","increment_by":10})
})

Example.Repo.insert!(%HeadwaterEventsSchema{
  event_id: 2,
  aggregate_id: "event-ordering",
  idempotency_id: "7f5f8326-1754-48b6-a949-1f6b41b0bdd1",
  event:
    ~s({"__struct__":"Elixir.Example.Incremented","counter_id":"event-ordering","increment_by":20})
})

# Event bus tracking

Example.Repo.insert!(%HeadwaterEventBusSchema{
  bus_id: "event_bus-one",
  event_ref: 15
})

# Idempotency
Example.Repo.insert!(%HeadwaterIdempotencySchema{
  id: "7f5f8326-1754-48b6-a949-1f6b41b0bdd1",
  idempotency_key: "7ccdc378a8a64e979ea2d1e1af27b56d"
})
Example.Repo.insert!(%HeadwaterIdempotencySchema{
  id: "d7425c16-62c7-4da9-acee-059acf6d641c",
  idempotency_key: "721f402bf8c14db78dec82346bee9ab4"
})
Example.Repo.insert!(%HeadwaterIdempotencySchema{
  id: "239dd70c-ddfb-4d11-a93d-3b2334a2b192",
  idempotency_key: "804ccbd800b34eb4b8586025cba5e95e"
})
Example.Repo.insert!(%HeadwaterIdempotencySchema{
  id: "63379329-faff-4f21-a48a-6d09034cf041",
  idempotency_key: "fae7885a73c3452eb7eb99b176baf0e3"
})
Example.Repo.insert!(%HeadwaterIdempotencySchema{
  id: "4ceeb017-bb5f-4cf2-a53b-c168500b89d7",
  idempotency_key: "6a59a72f50b0436fbfb3ca031d71d235"
})
Example.Repo.insert!(%HeadwaterIdempotencySchema{
  id: "ed428506-b897-443a-b5f5-08492b921349",
  idempotency_key: "f3e9ee81b8cd4283a40a4093b3ed551b"
})

IO.puts("Finished seed data.")

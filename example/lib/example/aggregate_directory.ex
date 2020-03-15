defmodule Example.Headwater.AggregateDirectory do
  use Headwater.AggregateDirectory,
    registry: Example.Registry,
    supervisor: Example.AggregateSupervisor,
    event_store: Example.EventStore,
    listener: ExampleListener
end

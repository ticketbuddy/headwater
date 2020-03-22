defmodule Example.Router do
  use Headwater.Aggregate.Router,
    config: %Headwater.Config{
      event_store: Example.EventStore,
      directory: Headwater.Aggregate.Directory,
      registry: Example.Registry,
      supervisor: Example.AggregateSupervisor
    }

  defread(:read_counter, to: Example.Counter)
end

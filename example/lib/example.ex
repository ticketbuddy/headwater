defmodule Example do
  import Headwater.Aggregate.Wish, only: [defwish: 3]

  defwish(Increment, [:counter_id, :increment_by], to: Example.Counter)
  defwish(MultiIncrement, [:counter_id, :increment_by, :increment_again], to: Example.Counter)
end

defmodule ExampleListener do
  use Headwater.Listener.Supervisor,
    from_event_ref: 0,
    busses: [
      {"first_bus", [Example.Printer]}
    ],
    config: %Headwater.Config{
      event_store: Example.EventStore,
      directory: Headwater.Aggregate.Directory,
      registry: Example.Registry,
      supervisor: Example.AggregateSupervisor
    }
end

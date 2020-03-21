defmodule Example do
  use Headwater.Aggregate.EntryPoint,
    config: %Headwater.Config{
      event_store: Example.EventStore,
      registry: Example.Registry,
      supervisor: Example.Supervisor
    }

  defaction(Example.Increment, to: Example.Counter, by_key: :counter_id)
  defread(:read_counter, to: Example.Counter)
end

defmodule ExampleListener do
  use Headwater.Listener.Supervisor,
    from_event_ref: 0,
    event_store: Example.EventStore,
    busses: [
      {"first_bus", [Example.Printer]}
    ]
end

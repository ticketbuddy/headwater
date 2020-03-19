defmodule Example do
  use Headwater.Aggregate.Router, aggregate_directory: Example.Headwater.AggregateDirectory

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

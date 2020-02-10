defmodule Example.Headwater.AggregateDirectory do
  use Headwater.AggregateDirectory,
    registry: Example.Registry,
    supervisor: Example.AggregateSupervisor,
    event_store: Example.EventStore
end

defmodule Example do
  use Headwater.Aggregate.Router, aggregate_directory: Example.Headwater.AggregateDirectory

  defaction(:inc, to: Example.Counter, by_key: :counter_id)
  defaction(:reduce, to: Example.Reducer, by_key: :counter_id, with_prefix: "reducer_")
  defread(:read_counter, to: Example.Counter)
  defread(:read_reducer, to: Example.Reducer, with_prefix: "reducer_")
end

defmodule Example.Printer do
  def handle_event(event, notes) do
    IO.inspect({event, notes}, label: "printer")

    :ok
  end
end

defmodule ExampleListener do
  use Headwater.Listener,
    from_event_ref: 0,
    event_store: Example.EventStore,
    bus_id: "example_consumer_one",
    handlers: [Example.Printer]
end

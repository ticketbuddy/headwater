defmodule Example do
  use Headwater.Aggregate.Router, aggregate_directory: Example.Headwater.AggregateDirectory

  defaction(:inc, to: Example.Counter, by_key: :counter_id)
  defaction(:reduce, to: Example.Reducer, by_key: :counter_id)
  defread(:read_counter, to: Example.Counter)
  defread(:read_reducer, to: Example.Reducer)
end

# defmodule ExampleListener do
#   use Headwater.Listener,
#     from_event_ref: 0,
#     event_store: Example.EventStore,
#     bus_id: "example_consumer_one",
#     handlers: [Example.Printer]
# end
#
# defmodule SecondExampleListener do
#   use Headwater.Listener,
#     from_event_ref: 0,
#     event_store: Example.EventStore,
#     bus_id: "example_consumer_two",
#     handlers: []
# end

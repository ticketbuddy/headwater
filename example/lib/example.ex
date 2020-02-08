defmodule Example.HeadwaterSpring do
  use HeadwaterSpring,
    registry: Example.Registry,
    supervisor: Example.StreamSupervisor,
    event_store: Example.EventStore
end

defmodule Example do
  use HeadwaterSpring.Router, spring: Example.HeadwaterSpring

  defaction(:inc, to: Example.Counter, by_key: :counter_id)
  defread(:read_counter, to: Example.Counter)
end

defmodule Example.Printer do
  def handle_event(event, notes) do
    IO.inspect({event, notes}, label: "printer")

    :ok
  end
end

defmodule ExampleFisherman do
  use HeadwaterFisherman,
    from_event_ref: 0,
    event_store: Example.EventStore,
    bus_id: "example_consumer_one",
    handlers: [Example.Printer]
end

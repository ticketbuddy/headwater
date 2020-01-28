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

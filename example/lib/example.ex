defmodule Example do
  def run_test(counter_id) do
    HeadwaterSpring.Stream.new(%HeadwaterSpring.Stream{
      id: counter_id,
      handler: Example.Counter,
      supervisor: Example.StreamSupervisor,
      registry: Example.Registry,
      event_store: Example.EventStore
    })
  end
end

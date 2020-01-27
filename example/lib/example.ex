defmodule Example.HeadwaterSpring do
  use HeadwaterSpring,
    registry: Example.Registry,
    supervisor: Example.StreamSupervisor,
    event_store: Example.EventStore
end

defmodule Example do
  def run_test(counter_id) do
    %HeadwaterSpring.Request{
      stream_id: counter_id,
      handler: Example.Counter,
      wish: %Example.IncrementCounter{qty: 1},
      idempotency_key: HeadwaterSpring.uuid()
    }
    |> Example.HeadwaterSpring.handle()
  end
end

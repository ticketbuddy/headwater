defmodule Headwater.Aggregate.Directory.WriteRequest do
  @enforce_keys [:aggregate_id, :handler, :wish, :idempotency_key]
  defstruct @enforce_keys
end

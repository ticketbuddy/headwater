defmodule Headwater.Aggregate.Directory.ReadRequest do
  @enforce_keys [:aggregate_id, :handler]
  defstruct @enforce_keys
end

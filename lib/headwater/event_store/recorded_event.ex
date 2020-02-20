defmodule Headwater.EventStore.RecordedEvent do
  @enforce_keys [:aggregate_id, :event_id, :idempotency_key, :data]
  defstruct @enforce_keys ++ [:event_ref]

  @type t :: %__MODULE__{}
end

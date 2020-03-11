defmodule Headwater.EventStore.PersistEvent do
  @moduledoc """
  PersistEvent represents an event before being persisted.

  NOTE: This means we won't know the `event_number` at this stage.
  """
  alias Headwater.EventStore.EventSerializer

  @enforce_keys [:data, :aggregate_id, :aggregate_number, :idempotency_key]
  defstruct @enforce_keys

  @type uuid :: String.t()
  @type t :: %Headwater.EventStore.PersistEvent{
          aggregate_number: non_neg_integer(),
          aggregate_id: uuid,
          data: String.t()
        }

  def new(data, aggregate_config, write_request) do
    %__MODULE__{
      aggregate_id: aggregate_config.id,
      aggregate_number: aggregate_config.aggregate_number,
      data: EventSerializer.serialize(data),
      idempotency_key: write_request.idempotency_key
    }
  end
end

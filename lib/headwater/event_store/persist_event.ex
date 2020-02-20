defmodule Headwater.EventStore.PersistEvent do
  @moduledoc """
  PersistEvent represents an event before being persisted.
  """
  alias Headwater.EventStore.EventSerializer

  @enforce_keys [:data, :aggregate_id, :aggregate_number]
  defstruct @enforce_keys

  @type uuid :: String.t()
  @type t :: %Headwater.EventStore.PersistEvent{
          aggregate_number: non_neg_integer(),
          aggregate_id: uuid,
          data: String.t()
        }

  def new(%{data: data, aggregate_number: aggregate_number, aggregate_id: aggregate_id}) do
    %__MODULE__{
      aggregate_id: aggregate_id,
      aggregate_number: aggregate_number,
      data: EventSerializer.serialize(data)
    }
  end
end

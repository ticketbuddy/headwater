defmodule Headwater.EventStore.RecordedEvent do
  @moduledoc """
    aggregate_id - Identifies the aggregate which state is built from events.

    event_id - A UUID identifier for the event.

    event_number - Auto increment positive integer, which is used to order all events.

    aggregate_number - Auto increment positive integer, which is used to
    order the event within other events on the same aggregate

    data - The business event, serialised for storage.

    created_at - The UTC datetime when the event was created.
  """

  @enforce_keys [
    :aggregate_id,
    :event_id,
    :event_number,
    :aggregate_number,
    :data,
    :created_at,
    :idempotency_key
  ]
  defstruct @enforce_keys

  @type uuid :: String.t()

  alias Headwater.EventStore.Adapters.Postgres.HeadwaterEventsSchema
  alias Headwater.EventStore.EventSerializer

  @type t :: %Headwater.EventStore.RecordedEvent{
          event_id: uuid(),
          event_number: non_neg_integer(),
          aggregate_id: String.t(),
          aggregate_number: non_neg_integer(),
          data: struct(),
          created_at: DateTime.t(),
          idempotency_key: String.t()
        }

  def new(event = %HeadwaterEventsSchema{}) do
    %__MODULE__{
      aggregate_id: event.aggregate_id,
      event_id: event.event_id,
      idempotency_key: event.idempotency_key,
      event_number: event.event_number,
      aggregate_number: event.aggregate_number,
      data: EventSerializer.deserialize(event.data),
      created_at: event.inserted_at
    }
  end
end

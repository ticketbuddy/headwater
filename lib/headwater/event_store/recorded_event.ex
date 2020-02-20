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

  @enforce_keys [:aggregate_id, :event_id, :event_number, :aggregate_number, :data, :created_at]
  defstruct @enforce_keys

  @type uuid :: String.t()

  @type t :: %Headwater.EventStore.RecordedEvent{
          event_id: uuid(),
          event_number: non_neg_integer(),
          aggregate_id: String.t(),
          aggregate_number: non_neg_integer(),
          data: binary(),
          created_at: DateTime.t()
        }
end

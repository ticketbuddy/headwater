defmodule HeadwaterSpring.EventStore do
  @moduledoc """
  Behaviour for storage & reading of events
  """

  @type stream_id :: String.t()
  @type events :: List.t()
  @type last_event_id :: String.t() | nil
  @type latest_event_id :: String.t()
  @type event_ref :: integer()
  @type idempotency_key :: String.t()

  @callback commit!(stream_id, last_event_id, events, idempotency_key) :: {:ok, latest_event_id}

  @callback load(stream_id) :: {:ok, events, last_event_id}

  @callback read_events(from_event_ref: event_ref, limit: integer()) :: events

  @callback has_wish_previously_succeeded?(idempotency_key) :: true | false
end

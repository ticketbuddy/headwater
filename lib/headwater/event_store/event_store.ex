defmodule Headwater.EventStore do
  @moduledoc """
  Behaviour for storage & reading of events
  """

  @type aggregate_id :: String.t()
  @type event :: Headwater.EventStore.Event.t()
  @type events :: [event]
  @type event_ref :: integer()
  @type base_event_ref :: integer()
  @type idempotency_key :: String.t()
  @type listener_id :: String.t()

  @callback commit(events) :: {:ok, events}
  @callback load_events(aggregate_id) :: {:ok, events}
  @callback has_wish_previously_succeeded?(idempotency_key) :: true | false
  @callback event_handled(listener_id: listener_id, event_ref: event_ref) :: :ok
  @callback next_listener_event_ref(listener_id, base_event_ref) :: event_ref
  @callback get_event(event_ref) :: {:ok, event}
end

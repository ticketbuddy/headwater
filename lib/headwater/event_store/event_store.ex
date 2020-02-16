defmodule Headwater.EventStore do
  @moduledoc """
  Behaviour for storage & reading of events
  """

  @type aggregate_id :: String.t()
  @type events :: List.t()
  @type last_event_id :: integer()
  @type latest_event_ref :: integer()
  @type latest_event_id :: integer()
  @type event_ref :: integer()
  @type base_event_ref :: integer()
  @type idempotency_key :: String.t()
  @type bus_id :: String.t()

  @callback commit!(aggregate_id, last_event_id, events, idempotency_key) ::
              {:ok,
               %{
                 latest_event_id: latest_event_id,
                 latest_event_ref: latest_event_ref
               }}

  @callback load(aggregate_id) :: {:ok, events, last_event_id}

  @callback read_events(from_event_ref: event_ref, limit: integer()) :: events

  @callback has_wish_previously_succeeded?(idempotency_key) :: true | false

  @callback bus_has_completed_event_ref(bus_id: String.t(), event_ref: String.t()) :: :ok

  @callback get_next_event_ref(bus_id, base_event_ref) :: integer()
end

defmodule Headwater.Listener.EventHandler do
  @type notes :: %{idempotency_key: String.t()}

  @callback listener_prefix() :: String.t()
  @callback handle_event(any(), notes) :: {:ok, any()} | :ok

  def fetch_event(event_ref, event_store) do
    {:ok, event} = event_store.get_event(event_ref)

    event
  end

  def build_handlers(event, handlers) do
    Stream.map(handlers, &{&1, event})
  end

  def callbacks(callbacks) do
    Stream.map(callbacks, fn {handler, event} ->
      notes = event_notes(handler, event)

      handler.handle_event(event.event, notes)
    end)
  end

  def mark_as_completed(callback_results, event_store, bus_id, event_ref) do
    Enum.all?(callback_results, fn
      {:ok, _result} -> true
      :ok -> true
      _error -> false
    end)
    |> case do
      true ->
        event_store.bus_has_completed_event_ref(bus_id: bus_id, event_ref: event_ref)
        :ok

      false ->
        {:error, :callback_errors}
    end
  end

  defp event_notes(handler, event) do
    %{
      event_ref: event.event_ref,
      aggregate_id: event.aggregate_id,
      effect_idempotent_key: build_causation_idempotency_key(handler, event),
      event_occurred_at: event.inserted_at
    }
  end

  defp build_causation_idempotency_key(handler, event) do
    (handler.listener_prefix() <> Integer.to_string(event.event_ref) <> event.aggregate_id)
    |> Headwater.Listener.web_safe_md5()
  end
end

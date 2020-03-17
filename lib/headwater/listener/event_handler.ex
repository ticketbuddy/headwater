defmodule Headwater.Listener.EventHandler do
  @type notes :: %{idempotency_key: String.t()}

  @callback listener_prefix() :: String.t()
  @callback handle_event(any(), notes) :: {:ok, any()} | :ok

  def build_callbacks(recorded_events, handlers) do
    Enum.map(recorded_events, &{&1, handlers})
  end

  def callbacks(callbacks, opts) do
    Enum.reduce_while(callbacks, :ok, fn callback, result ->
      case execute_callback(callback, opts) do
        :ok -> {:cont, :ok}
        {:error, :callback_errors} -> {:halt, {:error, :callback_errors}}
      end
    end)
  end

  defp execute_callback({recorded_event, handlers}, opts) do
    %{event_store: event_store, bus_id: bus_id} = opts

    handlers
    |> Enum.map(fn handler ->
      notes = event_notes(handler, recorded_event)
      handler.handle_event(recorded_event.data, notes)
    end)
    |> Enum.all?(fn
      {:ok, _result} -> true
      :ok -> true
      _error -> false
    end)
    |> case do
      true ->
        event_store.bus_has_completed_event_number(
          bus_id: bus_id,
          event_number: recorded_event.event_number
        )

        :ok

      false ->
        {:error, :callback_errors}
    end
  end

  defp event_notes(handler, recorded_event) do
    %{
      event_number: recorded_event.event_number,
      aggregate_number: recorded_event.aggregate_number,
      event_id: recorded_event.event_id,
      effect_idempotent_key: build_causation_idempotency_key(handler, recorded_event),
      event_occurred_at: recorded_event.created_at
    }
  end

  defp build_causation_idempotency_key(handler, event) do
    (handler.listener_prefix() <> Integer.to_string(event.event_number) <> event.aggregate_id)
    |> Headwater.web_safe_md5()
  end
end

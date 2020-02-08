defmodule Headwater.Listener.EventHandler do
  @type notes :: %{idempotency_key: String.t()}
  @callback handle_event(Headwater.Listener.Event.t(), notes) :: {:ok, any()} | :ok
end

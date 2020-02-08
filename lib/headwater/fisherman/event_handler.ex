defmodule Headwater.Fisherman.EventHandler do
  @type notes :: %{idempotency_key: String.t()}
  @callback handle_event(Headwater.Fisherman.Event.t(), notes) :: {:ok, any()} | :ok
end

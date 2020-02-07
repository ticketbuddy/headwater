defmodule HeadwaterFisherman.Fisherman.EventHandler do
  @type notes :: %{idempotency_key: String.t()}
  @callback handle_event(HeadwaterFisherman.Fisherman.Event.t(), notes) :: {:ok, any()} | :ok
end

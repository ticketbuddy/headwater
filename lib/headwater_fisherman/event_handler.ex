defmodule HeadwaterFisherman.Fisherman.EventHandler do
  @callback handle_event(HeadwaterFisherman.Fisherman.Event.t()) :: {:ok, any()} | :ok
end

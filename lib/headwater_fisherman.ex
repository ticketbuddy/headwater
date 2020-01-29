defmodule HeadwaterFisherman do
  @moduledoc """
  Reading events from an event stream.
  """

  def setup do
    HeadwaterFisherman.Fisherman.start_link()
    HeadwaterFisherman.HandleFish.start_link()
    HeadwaterFisherman.HandleFish.start_link()
    HeadwaterFisherman.HandleFish.start_link()

    # HeadwaterFisherman.Fisherman.sync_notify(%{event_id: 2})
  end
end

defmodule HeadwaterFisherman.HandleFish do
  use GenStage

  @doc "Starts the consumer."
  def start_link() do
    GenStage.start_link(__MODULE__, :ok)
  end

  def init(:ok) do
    {:consumer, :ok, subscribe_to: [HeadwaterFisherman.Fisherman]}
  end

  def handle_events(events, _from, state) do
    for event <- events do
      event.handler.handle_event(event)
    end

    {:noreply, [], state}
  end
end

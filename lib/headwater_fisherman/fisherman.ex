defmodule HeadwaterFisherman.Fisherman do
  alias HeadwaterFisherman.Fisherman.Event

  use GenStage

  @doc "Starts the broadcaster."
  def start_link() do
    GenStage.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @doc "Sends an event and returns only after the event is dispatched."
  def sync_notify(event = %Event{}, timeout \\ 5000) do
    GenStage.call(__MODULE__, {:notify, event}, timeout)
  end

  ## Callbacks

  def init(:ok) do
    {:producer, {:queue.new(), 0, 0}, dispatcher: GenStage.BroadcastDispatcher}
  end

  def handle_call({:notify, event}, from, state = {queue, pending_demand, last_event_id}) do
    should_continue? = event.event_id == last_event_id + 1

    case should_continue? do
      true ->
        queue = :queue.in({from, event}, queue)
        dispatch_events(queue, pending_demand, [], last_event_id)

      false ->
        {:reply, :no, [], state}
    end
  end

  def handle_demand(incoming_demand, {queue, pending_demand, last_event_id}) do
    dispatch_events(queue, incoming_demand + pending_demand, [], last_event_id)
  end

  defp dispatch_events(queue, 0, events, last_event_id) do
    {:noreply, Enum.reverse(events), {queue, 0, last_event_id}}
  end

  defp dispatch_events(queue, demand, events, last_event_id) do
    case :queue.out(queue) do
      {{:value, {from, event}}, queue} ->
        GenStage.reply(from, :ok)
        dispatch_events(queue, demand - 1, [event | events], event.event_id)

      {:empty, queue} ->
        {:noreply, Enum.reverse(events), {queue, demand, last_event_id}}
    end
  end
end

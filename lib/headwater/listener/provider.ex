defmodule Headwater.Listener.Provider do
  use GenStage
  require Logger
  # @from_event_ref unquote(from_event_ref)
  # @event_store unquote(event_store)
  # @bus_id unquote(bus_id)

  def start_link(opts) do
    %{bus_id: bus_id, from_event_ref: from_event_ref, event_store: event_store} = opts
    read_from = event_store.get_next_event_ref(bus_id, from_event_ref)
    init_state = {{:queue.new(), 0, read_from}, opts}

    Logger.log(:info, "#{bus_id} continuing from event ref: #{read_from}")

    GenStage.start_link(__MODULE__, init_state, name: bus_id)
  end

  # Callbacks

  @impl true
  def init(state) do
    {:producer, state, dispatcher: GenStage.BroadcastDispatcher}
  end

  def you_have_work_to_do() do
    send(__MODULE__, :check_for_recorded_events)

    :ok
  end

  @impl true
  def handle_info(:check_for_recorded_events, {state, _opts}) do
    {queue, pending_demand, latest_event_ref} = state

    # TODO fetch next event ref & load the next recorded events

    # cond do
    #   event_ref >= expected_next_event_ref ->
    #     queue = add_missed_event_refs_to_queue(queue, expected_next_event_ref, event_ref)
    #     flush_events({queue, pending_demand, event_ref}, [])
    #
    #   event_ref < expected_next_event_ref ->
    #     Logger.log(:warn, "Event already processed")
    #     {:noreply, [], state}
    # end
  end

  def handle_demand(demand, {state, _opts}) do
    {queue, pending_demand, latest_event_ref} = state
    flush_events({queue, pending_demand + demand, latest_event_ref}, [])
  end

  defp add_missed_event_refs_to_queue(queue, expected_next_event_ref, requested_event_ref) do
    expected_next_event_ref..requested_event_ref
    |> Enum.reduce(queue, fn event_ref_to_add, queue ->
      :queue.in(event_ref_to_add, queue)
    end)
  end

  defp flush_events(state = {_queue, pending_demand = 0, _latest_event_ref}, events_to_flush) do
    {:noreply, Enum.reverse(events_to_flush), state}
  end

  defp flush_events(state, events_to_flush) do
    {queue, pending_demand, latest_event_ref} = state

    case :queue.out(queue) do
      {{:value, event}, queue} ->
        flush_events({queue, pending_demand - 1, latest_event_ref}, [event | events_to_flush])

      {:empty, queue} ->
        {:noreply, Enum.reverse(events_to_flush), state}
    end
  end
end

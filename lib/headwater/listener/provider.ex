defmodule Headwater.Listener.Provider do
  use GenStage
  require Logger

  def start_link(opts) do
    %{bus_id: bus_id, from_event_ref: from_event_ref, event_store: event_store} = opts
    read_from = event_store.get_bus_next_event_number(bus_id, from_event_ref)
    init_state = {{:queue.new(), 0, read_from}, opts}

    Logger.log(:info, "#{bus_id} continuing from event ref: #{read_from}")

    GenStage.start_link(__MODULE__, init_state, name: bus_id)
  end

  # Callbacks

  @impl true
  def init(state) do
    {:producer, state, dispatcher: GenStage.BroadcastDispatcher}
  end

  def check_for_recorded_events() do
    send(__MODULE__, :check_for_recorded_events)

    :ok
  end

  @impl true
  def handle_info(:check_for_recorded_events, {state, opts}) do
    {queue, pending_demand, latest_event_ref} = state
    %{event_store: event_store, bus_id: bus_id} = opts

    {queue, recorded_event_count} =
      event_store.load_events(latest_event_ref)
      |> Enum.reduce({queue, 0}, fn recorded_event, {queue, counter} ->
        queue = :queue.in(recorded_event, queue)

        {queue, counter + 1}
      end)

    flush_events({queue, pending_demand, latest_event_ref + recorded_event_count}, [], opts)
  end

  def handle_demand(demand, {state, opts}) do
    {queue, pending_demand, latest_event_ref} = state
    flush_events({queue, pending_demand + demand, latest_event_ref}, [], opts)
  end

  defp flush_events(
         state = {_queue, pending_demand = 0, _latest_event_ref},
         events_to_flush,
         opts
       ) do
    {:noreply, Enum.reverse(events_to_flush), {state, opts}}
  end

  defp flush_events(state, events_to_flush, opts) do
    {queue, pending_demand, latest_event_ref} = state

    case :queue.out(queue) do
      {{:value, event}, queue} ->
        flush_events(
          {queue, pending_demand - 1, latest_event_ref},
          [event | events_to_flush],
          opts
        )

      {:empty, queue} ->
        {:noreply, Enum.reverse(events_to_flush), {state, opts}}
    end
  end
end

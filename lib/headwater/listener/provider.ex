defmodule Headwater.Listener.Provider do
  defmacro __using__(
             from_event_ref: from_event_ref,
             event_store: event_store,
             bus_id: bus_id
           ) do
    quote do
      use GenStage
      require Logger
      @from_event_ref unquote(from_event_ref)
      @event_store unquote(event_store)
      @bus_id unquote(bus_id)

      def start_link(_) do
        read_from = @event_store.get_next_event_ref(@bus_id, @from_event_ref)
        init_state = {:queue.new(), 0, read_from}

        Logger.log(:info, "#{@bus_id} continuing from event ref: #{read_from}")

        GenStage.start_link(__MODULE__, init_state, name: __MODULE__)
      end

      # Callbacks

      @impl true
      def init(state) do
        {:producer, state, dispatcher: GenStage.BroadcastDispatcher}
      end

      def bus_id, do: @bus_id

      def process_event(event_ref) do
        send(__MODULE__, {:new_event_ref, event_ref})

        :ok
      end

      @impl true
      def handle_info({:new_event_ref, event_ref}, state) do
        {queue, pending_demand, latest_event_ref} = state
        expected_next_event_ref = latest_event_ref + 1

        cond do
          event_ref == expected_next_event_ref ->
            flush_events({:queue.in(event_ref, queue), pending_demand, event_ref}, [])

          event_ref > expected_next_event_ref ->
            Logger.log(:error, "Event from the future!")
            raise "Received event from the future"

          event_ref < expected_next_event_ref ->
            Logger.log(:error, "Event already processed")
            raise "Event already processed!"
        end
      end

      def handle_demand(demand, {queue, pending_demand, latest_event_ref}) do
        flush_events({queue, pending_demand + demand, latest_event_ref}, [])
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
  end
end

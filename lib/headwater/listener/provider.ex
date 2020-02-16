defmodule Headwater.Listener.Provider do
  @moduledoc """
  Provider of events for a single EventBus. It fetches
  the next series of events to be projected, for the EventBusConsumer
  to use.

  This Provider does not filter any event types. It is up to the logic
  in the `handle_event/1` callback of the consumer to filter the events
  that the projector wishes to handle.

  Specify a `from_event_ref` value to dictate the first event that this
  bus should load. This allows projectors to skip the first `x` of
  of events, which is useful if the projector is for sending emails or
  other notifications, which have no relevance for very historic events.

  The bus is notified of when to check the database for more events
  via an `info` message sent by the EventStore once a new event has been
  committed.
  """
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

        GenStage.start_link(__MODULE__, read_from, name: __MODULE__)
      end

      # Callbacks

      @impl true
      def init(state) do
        {:producer, state, dispatcher: GenStage.BroadcastDispatcher}
      end

      @impl true
      def handle_demand(demand, state) do
        Logger.log(
          :info,
          "Provider handling demand for up to #{demand} new events, from event ref #{state}."
        )

        read_new_events(state, limit: demand)
      end

      @impl true
      def handle_info(:check_for_new_data, state) do
        # TODO: also get the event_ref, and compare to the
        # event_ref held in the state.

        limit = 10

        Logger.log(
          :info,
          "Provider checking for up to #{limit} new events, from event ref #{state}."
        )

        read_new_events(state, limit: limit)
      end

      @impl true
      def handle_info({:event_processed, event_ref}, _state) do
        Logger.log(:info, "Listener #{@bus_id}, completed event ref: #{event_ref}")

        @event_store.bus_has_completed_event_ref(
          bus_id: @bus_id,
          event_ref: event_ref
        )

        {:noreply, [], event_ref}
      end

      defp read_new_events(read_from, limit: limit) do
        events = @event_store.read_events(from_event_ref: read_from, limit: limit)

        case events do
          [] ->
            Logger.log(:info, "no new events, #{read_from} was the last")
            {:noreply, events, read_from}

          _not_empty ->
            last_event = List.last(events)
            Logger.log(:info, "read new events, up to #{last_event.event_ref}")
            {:noreply, events, last_event.event_ref}
        end
      end
    end
  end
end

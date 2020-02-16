defmodule Headwater.Listener.Consumer do
  @callback handle_events() :: {:noreply, [], :no_meaningful_state}
  @callback handle_event(any()) :: :ok | :error

  defmacro __using__(
             provider: provider,
             retry_limit: retry_limit,
             event_store: event_store,
             handlers: handlers
           ) do
    quote do
      use GenStage
      require Logger
      @provider unquote(provider)
      @event_store unquote(event_store)
      @retry_limit unquote(retry_limit)
      @handlers unquote(handlers)

      alias Headwater.Listener.EventHandler

      def start_link(_) do
        GenStage.start_link(__MODULE__, :no_meaningful_state)
      end

      @impl true
      def init(state) do
        {:consumer, state, subscribe_to: [{@provider, max_demand: 1}]}
      end

      @impl true
      def handle_events([event_ref], _from, state) do
        event_ref
        |> EventHandler.fetch_event(@event_store)
        |> EventHandler.build_handlers(@handlers)
        |> EventHandler.callbacks()
        |> EventHandler.mark_as_completed(@event_store, @provider.bus_id(), event_ref)
        |> case do
          :ok ->
            {:noreply, [], state}

          {:error, :callback_errors} ->
            # TODO handle this better...
            raise "Callback had errors"
        end
      end

      @impl true
      def handle_events(_events, _from, _state) do
        raise "Only one event at a time."
      end
    end
  end
end

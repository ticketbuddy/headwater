defmodule Headwater.Listener.Consumer do
  @moduledoc """
  A GenStage consumer for the consumption of events
  from a single EventBus, that has fetched from the DB.

  The EventBusConsumer is a one-to-one mapping with the EventBusProducer,
  because this way, we can be sure to manage the events
  in order per consumer, and with a clear starting point
  via the `from_event_ref` value in the consumer's corresponding
  EventBus.

  For each event received, it runs the handle_event/1
  callback. It will keep retrying the callback until
  it returns `:ok`

  Once the handle_event/1 callback returns `:ok`, then
  a message is sent to the bus to inform it of the
  successfully handled event.
  """
  @callback handle_events() :: {:noreply, [], :no_meaningful_state}
  @callback handle_event(any()) :: :ok | :error

  defmacro __using__(provider: provider, retry_limit: retry_limit, handlers: handlers) do
    quote do
      use GenStage
      @provider unquote(provider)
      @retry_limit unquote(retry_limit)
      @handlers unquote(handlers)

      def start_link(_) do
        GenStage.start_link(__MODULE__, :no_meaningful_state)
      end

      @impl true
      def init(state) do
        {:consumer, state, subscribe_to: [@provider]}
      end

      @impl true
      def handle_events(events, _from, state) do
        for event <- events do
          event_handler_callback!(event)
          :ok
        end

        {:noreply, [], state}
      end

      defp event_handler_callback!(event, attempt \\ 0) when attempt < @retry_limit do
        :timer.sleep(:rand.uniform(100) * (attempt * 3))

        handle_result =
          @handlers
          |> Enum.all?(fn handler ->
            case handler.handle_event(event.event, event_notes(event)) do
              :ok -> true
              {:ok, _} -> true
              _other_result -> false
            end
          end)

        case handle_result do
          true ->
            notify_producer_of_completed_event(event.event_ref)
            :ok

          false ->
            event_handler_callback!(event, attempt + 1)
        end
      end

      defp event_notes(event) do
        %{
          event_ref: event.event_ref,
          stream_id: event.stream_id,
          effect_idempotent_key: build_causation_idempotency_key(event),
          event_occurred_at: event.inserted_at
        }
      end

      defp build_causation_idempotency_key(event) do
        (Integer.to_string(event.event_ref) <> event.stream_id)
        |> Headwater.Listener.web_safe_md5()
      end

      defp event_handler_callback!(_event, _attempt) do
        raise "Max retry limit reached"
      end

      defp notify_producer_of_completed_event(event_ref) do
        send(@provider, {:event_processed, event_ref})
      end
    end
  end
end

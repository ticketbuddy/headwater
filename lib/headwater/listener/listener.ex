defmodule Headwater.Listener do
  @moduledoc """
  Reading events from an event aggregate.
  """
  @type event_ref :: integer()
  @callback process_event_ref(event_ref) :: :ok

  defmacro __using__(
             from_event_ref: from_event_ref,
             event_store: event_store,
             bus_id: bus_id,
             handlers: handlers
           ) do
    quote do
      defmodule Provider do
        use Headwater.Listener.Provider,
          from_event_ref: unquote(from_event_ref),
          event_store: unquote(event_store),
          bus_id: unquote(bus_id)
      end

      defmodule Consumer do
        use Headwater.Listener.Consumer,
          provider: Provider,
          retry_limit: 5,
          event_store: unquote(event_store),
          handlers: unquote(handlers)
      end

      def process_event_ref(event_ref) do
        Provider.process_event(event_ref)
      end

      def children do
        [Provider, Consumer]
      end
    end
  end
end

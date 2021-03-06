defmodule Headwater.Listener.Supervisor do
  @moduledoc """
  Starts and supervises listener processes
  """
  @type event_ref :: integer()
  @callback process_event_ref(event_ref) :: :ok

  defmacro __using__(
             from_event_ref: from_event_ref,
             busses: busses,
             config: config
           ) do
    quote do
      use Supervisor
      require Logger
      @busses unquote(busses)
      @config unquote(config)

      def start_link(init_arg) do
        Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
      end

      @impl true
      def init(args) do
        Supervisor.init(children(), strategy: :one_for_one)
      end

      def children do
        children = @busses |> Enum.flat_map(&bus_process_description/1)
      end

      def broadcast_check_for_recorded_events() do
        Logger.info(fn -> "Asking all listeners to check for recorded events." end)

        @busses
        |> Enum.each(fn {bus_id, _handlers} ->
          Headwater.Listener.Provider.check_for_recorded_events(bus_id)
        end)
      end

      defp bus_process_description({bus_id, handlers}) do
        [
          Supervisor.child_spec({Headwater.Listener.Provider, provider_args(bus_id)},
            id: "headwater_provider_#{bus_id}"
          ),
          Supervisor.child_spec({Headwater.Listener.Consumer, consumer_args(bus_id, handlers)},
            id: "headwater_consumer_#{bus_id}"
          )
        ]
      end

      defp provider_args(bus_id) do
        %{
          bus_id: bus_id,
          event_store: @config.event_store,
          from_event_ref: unquote(from_event_ref)
        }
      end

      defp consumer_args(bus_id, handlers) do
        %{
          bus_id: bus_id,
          event_store: @config.event_store,
          handlers: handlers,
          router: @config.router
        }
      end
    end
  end
end

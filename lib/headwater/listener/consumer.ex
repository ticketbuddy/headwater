defmodule Headwater.Listener.Consumer do
  @callback handle_events() :: {:noreply, [], :no_meaningful_state}
  @callback handle_event(any()) :: :ok | :error

  use GenStage
  require Logger

  alias Headwater.Listener.EventHandler

  def start_link(opts) do
    GenStage.start_link(__MODULE__, opts, name: :"consumer_#{opts.bus_id}")
  end

  @impl true
  def init(%{bus_id: bus_id} = state) do
    {:consumer, state, subscribe_to: [:"provider_#{bus_id}"]}
  end

  @impl true
  def handle_events(recorded_events, _from, state) do
    %{handlers: handlers, event_store: event_store, bus_id: bus_id} = state

    # TODO for each recorded event, call all callbacks
    recorded_events
    |> EventHandler.build_callbacks(handlers)
    |> EventHandler.callbacks(state)
    |> case do
      :ok ->
        {:noreply, [], state}

      {:error, :callback_errors} ->
        # TODO handle this better...
        raise "Callback had errors"
    end

    {:noreply, [], state}
  end
end

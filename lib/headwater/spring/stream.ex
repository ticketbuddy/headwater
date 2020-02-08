defmodule Headwater.Spring.Stream do
  @enforce_keys [:id, :handler, :registry, :supervisor, :event_store]
  defstruct @enforce_keys

  use GenServer

  @moduledoc """
  Start a new stream
  """
  def new(stream = %__MODULE__{}) do
    opts = [
      stream: stream,
      name: via_tuple(stream)
    ]

    DynamicSupervisor.start_child(stream.supervisor, {__MODULE__, opts})
  end

  def propose_wish(stream, wish, idempotency_key) do
    GenServer.call(via_tuple(stream), {:wish, stream.id, wish, idempotency_key})
  end

  def current_state(stream) do
    GenServer.call(via_tuple(stream), :state)
  end

  defp via_tuple(stream) do
    {:via, Registry, {stream.registry, stream.id}}
  end

  def init(init_state), do: {:ok, init_state}

  def start_link(opts) do
    {name, opts} = Keyword.pop(opts, :name)
    {stream, opts} = Keyword.pop(opts, :stream)

    case GenServer.start_link(__MODULE__, %{stream: stream}, name: name) do
      {:ok, pid} ->
        GenServer.call(name, {:load_state_from_events, stream.id})
        {:ok, pid}

      {:error, {:already_started, pid}} ->
        {:ok, pid}
    end
  end

  # Server callbacks

  def handle_call({:load_state_from_events, stream_id}, _from, state = %{stream: stream}) do
    {:ok, events, last_event_id} = stream.event_store.load(stream.id)

    state = %{
      stream: stream,
      stream_state: reduce_events_to_state(stream, events),
      last_event_id: last_event_id
    }

    {:reply, :ok, state}
  end

  @impl true
  def handle_call(
        :state,
        _from,
        state = %{last_event_id: last_event_id, stream_state: stream_state}
      ) do
    {:reply, {:ok, {last_event_id, stream_state}}, state}
  end

  def handle_call(
        {:wish, stream_id, wish, idempotency_key},
        _from,
        state = %{
          stream: stream,
          stream_state: stream_state,
          last_event_id: last_event_id
        }
      ) do
    with {:ok, new_event} <- execute_wish_on_stream(stream, stream_state, wish),
         {:ok, new_stream_state} <- next_state_for_stream(stream, stream_state, new_event),
         {:ok, latest_event_id} <-
           stream.event_store.commit!(stream_id, last_event_id, new_event, idempotency_key) do
      updated_state = %{
        stream: stream,
        stream_state: new_stream_state,
        last_event_id: latest_event_id
      }

      {:reply, {:ok, {latest_event_id, new_stream_state}}, updated_state}
    else
      {:error, :wish_already_completed} ->
        {:reply, {:ok, {last_event_id, stream_state}}, state}

      error = {:error, :execute, _} ->
        case has_wish_previously_succeeded?(stream, idempotency_key) do
          true -> {:reply, {:ok, {last_event_id, stream_state}}, state}
          false -> {:reply, error, state}
        end

      error = {:error, :next_state, _} ->
        {:reply, error, state}
    end
  end

  defp execute_wish_on_stream(stream, stream_state, wish) do
    case stream.handler.execute(stream_state, wish) do
      {:ok, event} -> {:ok, event}
      result -> {:error, :execute, result}
    end
  end

  defp next_state_for_stream(stream, stream_state, new_event) do
    case stream.handler.next_state(stream_state, new_event) do
      response = {:error, reason} -> {:error, :next_state, response}
      new_stream_state -> {:ok, new_stream_state}
    end
  end

  defp reduce_events_to_state(stream, events) do
    events
    |> Enum.reduce(nil, &stream.handler.next_state(&2, &1.event))
  end

  defp has_wish_previously_succeeded?(stream, idempotency_key) do
    stream.event_store.has_wish_previously_succeeded?(idempotency_key)
  end
end

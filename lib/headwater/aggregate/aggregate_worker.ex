defmodule Headwater.Aggregate.AggregateWorker do
  @enforce_keys [:id, :handler, :registry, :supervisor, :event_store]
  defstruct @enforce_keys

  use GenServer
  alias Headwater.Aggregate.{NextState, ExecuteWish}

  @moduledoc """
  Start a new aggregate
  """
  def new(aggregate = %__MODULE__{}) do
    opts = [
      aggregate: aggregate,
      name: via_tuple(aggregate)
    ]

    DynamicSupervisor.start_child(aggregate.supervisor, {__MODULE__, opts})
  end

  def propose_wish(aggregate, wish, idempotency_key) do
    GenServer.call(via_tuple(aggregate), {:wish, aggregate.id, wish, idempotency_key})
  end

  def current_state(aggregate) do
    GenServer.call(via_tuple(aggregate), :state)
  end

  defp via_tuple(aggregate) do
    {:via, Registry, {aggregate.registry, aggregate.id}}
  end

  def init(init_state), do: {:ok, init_state}

  def start_link(opts) do
    {name, opts} = Keyword.pop(opts, :name)
    {aggregate, opts} = Keyword.pop(opts, :aggregate)

    case GenServer.start_link(__MODULE__, %{aggregate: aggregate}, name: name) do
      {:ok, pid} ->
        GenServer.call(name, {:load_state_from_events, aggregate.id})
        {:ok, pid}

      {:error, {:already_started, pid}} ->
        {:ok, pid}
    end
  end

  # Server callbacks

  def handle_call({:load_state_from_events, aggregate_id}, _from, state = %{aggregate: aggregate}) do
    # TODO: EventStore.load/1 loads all the events into memory
    # before processing them to obtain the next state.
    # There must be a more efficient way of doing this...

    {:ok, events, last_event_id} = aggregate.event_store.load(aggregate.id)
    {:ok, aggregate_state} = NextState.process(aggregate, nil, events)

    state = %{
      aggregate: aggregate,
      aggregate_state: aggregate_state,
      last_event_id: last_event_id
    }

    {:reply, :ok, state}
  end

  @impl true
  def handle_call(
        :state,
        _from,
        state = %{last_event_id: last_event_id, aggregate_state: aggregate_state}
      ) do
    {:reply, {:ok, {last_event_id, aggregate_state}}, state}
  end

  def handle_call(
        {:wish, aggregate_id, wish, idempotency_key},
        _from,
        state = %{
          aggregate: aggregate,
          aggregate_state: aggregate_state,
          last_event_id: last_event_id
        }
      ) do
    with {:ok, new_events} <- ExecuteWish.process(aggregate, aggregate_state, wish),
         {:ok, new_aggregate_state} <-
           NextState.process(aggregate, aggregate_state, new_events),
         {:ok, latest_event_id} <-
           aggregate.event_store.commit!(aggregate_id, last_event_id, new_events, idempotency_key) do
      updated_state = %{
        aggregate: aggregate,
        aggregate_state: new_aggregate_state,
        last_event_id: latest_event_id
      }

      {:reply, {:ok, {latest_event_id, new_aggregate_state}}, updated_state}
    else
      {:error, :wish_already_completed} ->
        {:reply, {:ok, {last_event_id, aggregate_state}}, state}

      error = {:error, :execute, _} ->
        case has_wish_previously_succeeded?(aggregate, idempotency_key) do
          true -> {:reply, {:ok, {last_event_id, aggregate_state}}, state}
          false -> {:reply, error, state}
        end

      error = {:error, :next_state, _} ->
        {:reply, error, state}
    end
  end

  defp has_wish_previously_succeeded?(aggregate, idempotency_key) do
    aggregate.event_store.has_wish_previously_succeeded?(idempotency_key)
  end
end

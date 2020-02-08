defmodule Headwater.Spring.Aggregate do
  @enforce_keys [:id, :handler, :registry, :supervisor, :event_store]
  defstruct @enforce_keys

  use GenServer

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
    {:ok, events, last_event_id} = aggregate.event_store.load(aggregate.id)

    state = %{
      aggregate: aggregate,
      aggregate_state: reduce_events_to_state(aggregate, events),
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
    with {:ok, new_event} <- execute_wish_on_aggregate(aggregate, aggregate_state, wish),
         {:ok, new_aggregate_state} <-
           next_state_for_aggregate(aggregate, aggregate_state, new_event),
         {:ok, latest_event_id} <-
           aggregate.event_store.commit!(aggregate_id, last_event_id, new_event, idempotency_key) do
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

  defp execute_wish_on_aggregate(aggregate, aggregate_state, wish) do
    case aggregate.handler.execute(aggregate_state, wish) do
      {:ok, event} -> {:ok, event}
      result -> {:error, :execute, result}
    end
  end

  defp next_state_for_aggregate(aggregate, aggregate_state, new_event) do
    case aggregate.handler.next_state(aggregate_state, new_event) do
      response = {:error, reason} -> {:error, :next_state, response}
      new_aggregate_state -> {:ok, new_aggregate_state}
    end
  end

  defp reduce_events_to_state(aggregate, events) do
    events
    |> Enum.reduce(nil, &aggregate.handler.next_state(&2, &1.event))
  end

  defp has_wish_previously_succeeded?(aggregate, idempotency_key) do
    aggregate.event_store.has_wish_previously_succeeded?(idempotency_key)
  end
end

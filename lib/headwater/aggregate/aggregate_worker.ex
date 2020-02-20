defmodule Headwater.Aggregate.AggregateWorker do
  use GenServer

  alias Headwater.Aggregate.AggregateConfig
  alias Headwater.Aggregate.{NextState, ExecuteWish}
  alias Headwater.AggregateDirectory.WriteRequest
  require Logger

  @moduledoc """
  Start a new aggregate
  """
  def new(aggregate = %AggregateConfig{}) do
    opts = [
      aggregate: aggregate,
      name: via_tuple(aggregate)
    ]

    DynamicSupervisor.start_child(aggregate.supervisor, {__MODULE__, opts})
  end

  def propose_wish(aggregate, write_request = %WriteRequest{}) do
    GenServer.call(via_tuple(aggregate), {:wish, write_request})
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

    case GenServer.start_link(__MODULE__, aggregate, name: name) do
      {:ok, pid} ->
        GenServer.call(name, {:load_state_from_events, aggregate.id})
        {:ok, pid}

      {:error, {:already_started, pid}} ->
        {:ok, pid}
    end
  end

  # Server callbacks

  def handle_call({:load_state_from_events, aggregate_id}, _from, state) do
    aggregate = state
    # TODO: EventStore.load/1 loads all the events into memory
    # before processing them to obtain the next state.
    # There must be a more efficient way of doing this...

    {:ok, events} = aggregate.event_store.load_events(aggregate.id)

    business_domain_events = get_in(events, [Access.all(), Access.key(:event)])

    {:ok, aggregate_state, aggregate_number} =
      NextState.process(aggregate, nil, business_domain_events)

    state = %{
      aggregate: aggregate,
      aggregate_state: aggregate_state,
      aggregate_number: aggregate_number
    }

    {:reply, :ok, state}
  end

  @impl true
  def handle_call(
        :state,
        _from,
        state
      ) do
    %AggregateConfig{aggregate_number: aggregate_number, aggregate_state: aggregate_state} = state
    {:reply, {:ok, {aggregate_number, aggregate_state}}, state}
  end

  def handle_call(
        {:wish, write_request = %WriteRequest{}},
        _from,
        state
      ) do
    aggregate_config = state

    with {:ok, persist_events} <- ExecuteWish.process(aggregate_config, wish),
         {:ok, recorded_events} <-
           aggregate.event_store.commit(persist_events,
             idempotency_key: write_request.idempotency_key
           ),
         {:ok, new_aggregate_state, aggregate_number} <-
           NextState.process(aggregate, aggregate_state, recorded_events) do
      {:reply, {:ok, {latest_event_ref, latest_event_id, new_aggregate_state}}, aggregate_config}
    else
      {:error, :wish_already_completed} ->
        {:reply, {:ok, {aggregate_number, aggregate_state}}, state}

      error = {:error, :execute, _} ->
        case has_wish_previously_succeeded?(aggregate, idempotency_key) do
          true -> {:reply, {:ok, {aggregate_number, aggregate_state}}, state}
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

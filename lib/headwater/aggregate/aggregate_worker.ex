defmodule Headwater.Aggregate.AggregateWorker do
  use GenServer

  alias Headwater.Aggregate.{NextState, ExecuteWish, AggregateConfig, Idempotency}
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

  def latest_aggregate_number(aggregate) do
    GenServer.call(via_tuple(aggregate), :aggregate_number)
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

    {:ok, recorded_events} = aggregate.event_store.load_events(aggregate.id)

    {:ok, aggregate_config} = NextState.process(aggregate, recorded_events)

    {:reply, :ok, aggregate_config}
  end

  @impl true
  def handle_call(
        :state,
        _from,
        state
      ) do
    %AggregateConfig{aggregate_state: aggregate_state} = state
    {:reply, {:ok, aggregate_state}, state}
  end

  @impl true
  def handle_call(
        :aggregate_number,
        _from,
        state
      ) do
    %AggregateConfig{aggregate_number: aggregate_number} = state
    {:reply, {:ok, aggregate_number}, state}
  end

  def handle_call(
        {:wish, write_request = %WriteRequest{}},
        _from,
        state
      ) do
    aggregate_config = state

    with {:ok, :idempotency_key_available} <-
           Idempotency.key_status(aggregate_config, write_request.idempotency_key),
         {:ok, {aggregate_config, persist_events}} <-
           ExecuteWish.process(aggregate_config, write_request),
         {:ok, recorded_events} <-
           aggregate_config.event_store.commit(persist_events,
             idempotency_key: write_request.idempotency_key
           ),
         {:ok, aggregate_config} <-
           NextState.process(aggregate_config, recorded_events) do
      {:reply, {:ok, aggregate_config.aggregate_state}, aggregate_config}
    else
      {:error, :idempotency_key_used} ->
        {:reply, {:ok, aggregate_config.aggregate_state}, state}

      error = {:error, :execute, _} ->
        {:reply, error, state}

      error = {:error, :next_state, _} ->
        {:reply, error, state}
    end
  end
end

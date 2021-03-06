defmodule Headwater.Aggregate.AggregateWorker do
  use GenServer

  alias Headwater.Aggregate.{NextState, ExecuteWish, AggregateConfig, Idempotency}
  alias Headwater.Aggregate.Directory.WriteRequest
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
    {:ok, recorded_events} = aggregate.event_store.load_events_for_aggregate(aggregate.id)

    {:ok, aggregate_config} = NextState.process(aggregate, Enum.to_list(recorded_events))

    Logger.info(fn ->
      "Loaded #{Enum.count(recorded_events)} recorded events for #{aggregate.id}. Aggregate number now #{
        aggregate_config.aggregate_number
      }."
    end)

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
           Idempotency.key_status(write_request.idempotency_key),
         {:ok, {aggregate_config, persist_events}} <-
           ExecuteWish.process(aggregate_config, write_request),
         {:ok, recorded_events} <- aggregate_config.event_store.commit(persist_events),
         {:ok, aggregate_config} <-
           NextState.process(aggregate_config, recorded_events) do
      {:reply, {:ok, aggregate_config.aggregate_state}, aggregate_config}
    else
      {:warn, :idempotency_key_used} ->
        Logger.warn("Idempotency key already used for wish.")
        {:reply, {:ok, aggregate_config.aggregate_state}, state}

      error = {:error, :execute, _} ->
        Logger.error("Error execute wish; #{inspect(error)}")
        {:reply, error, state}

      error = {:error, :next_state, _} ->
        Logger.error("Error next_state wish; #{inspect(error)}")
        {:reply, error, state}

      {:error, :commit_error} ->
        Logger.error("EventStore commit error")
    end
  end
end

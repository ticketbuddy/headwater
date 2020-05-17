defmodule Headwater.Aggregate.Idempotency do
  @moduledoc """
  This module records idempotency keys used on an aggregate.
  It allows queries to see if an idempotency key has been used already.

  Idempotency keys are recorded with the events in the event store. We do
  not rely on the DB for idempotency (we could do, but it's less performant).

  Instead, we load all idempotency keys into an ets table as `next_state`
  callback is ran, and check the ets table for the idempotency key.

  The `aggregate_number` ensures that the recorded events have been loaded to
  build the aggregate's state. Therefore, we can also rely on all the
  `idempotency_key`s being loaded into ets for that aggregate.
  """
  require Logger
  alias Headwater.Aggregate.AggregateConfig

  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: :headwater_idempotency_ets)
  end

  def init(init_state) do
    :ets.new(:headwater_idempotency, [:set, :public, :named_table, read_concurrency: true])

    {:ok, init_state}
  end

  def store(idempotency_key) do
    Logger.info("Recording idempotency key #{idempotency_key}.")
    :ets.insert(:headwater_idempotency, {idempotency_key})
  end

  def key_status(idempotency_key) do
    :ets.lookup(:headwater_idempotency, idempotency_key)
    |> case do
      [] ->
        Logger.info("Idempotency key #{idempotency_key} not used.")
        {:ok, :idempotency_key_available}

      [{^idempotency_key}] ->
        Logger.info("Idempotency key #{idempotency_key} used.")
        {:warn, :idempotency_key_used}
    end
  end
end

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

  def store(aggregate_config = %AggregateConfig{}, idempotency_key) do
    Logger.info("Recording idempotency key #{idempotency_key}.")

    aggregate_config
    |> ensure_started()
    |> table_name()
    |> :ets.insert({idempotency_key})

    aggregate_config
  end

  def key_status(aggregate_config = %AggregateConfig{}, idempotency_key) do
    aggregate_config
    |> ensure_started()
    |> table_name()
    |> :ets.lookup(idempotency_key)
    |> case do
      [] ->
        Logger.info("Idempotency key #{idempotency_key} not used.")
        {:ok, :idempotency_key_available}

      [{^idempotency_key}] ->
        Logger.info("Idempotency key #{idempotency_key} used.")
        {:error, :idempotency_key_used}
    end
  end

  defp ensure_started(aggregate_config = %AggregateConfig{}) do
    idempotency_table = table_name(aggregate_config)

    case :ets.whereis(idempotency_table) do
      :undefined ->
        :ets.new(idempotency_table, [:set, :protected, :named_table, read_concurrency: true])
        aggregate_config

      _reference ->
        aggregate_config
    end
  end

  defp table_name(%AggregateConfig{id: aggregate_id}) do
    :"headwater_idem_#{aggregate_id}"
  end
end

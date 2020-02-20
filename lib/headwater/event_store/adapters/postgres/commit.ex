defmodule Headwater.EventStore.Adapters.Postgres.Commit do
  require Logger
  alias Ecto.Multi
  alias Headwater.EventStore.Adapters.Postgres.{HeadwaterEventsSchema, HeadwaterIdempotencySchema}

  def add_idempotency(multi, idempotency_key) do
    multi
    |> Multi.insert(
      :idempotency_check,
      HeadwaterIdempotencySchema.changeset(%{idempotency_key: idempotency_key})
    )
  end

  def add_inserts(multi, persist_events) do
    persist_events
    |> Enum.reduce(multi, fn persist_event, multi ->
      multi
      |> Multi.insert(
        :"event_#{persist_event.aggregate_number}",
        HeadwaterEventsSchema.changeset(persist_event),
        returning: [:event_id, :event_number]
      )
    end)
  end

  def add_results(multi) do
    multi
    |> Multi.run(:results, fn _repo, changes ->
      {:ok, get_latest_event_ref_and_id(changes)}
    end)
  end

  def get_latest_event_ref_and_id(change_result) do
    default_results = %{
      latest_event_id: 0,
      latest_event_ref: 0
    }

    Enum.reduce(change_result, default_results, fn
      {_key, inserted_event = %HeadwaterEventsSchema{}}, curr_results ->
        %{
          latest_event_id: max(inserted_event.event_id, curr_results.latest_event_id),
          latest_event_ref: max(inserted_event.event_ref, curr_results.latest_event_ref)
        }

      {_key, _value}, results ->
        results
    end)
  end

  def on_commit_result({:ok, %{results: results}}) do
    {:ok, results}
  end

  def on_commit_result(
        {:error, :idempotency_check, error = %Ecto.Changeset{errors: errors}, _changes}
      ) do
    case Keyword.has_key?(errors, :wish_already_completed) do
      true ->
        Logger.log(:info, "idempotency_key already used")
        {:error, :wish_already_completed}

      false ->
        Logger.log(:error, "inserting idempotency_key failed: #{inspect(error)}")
        {:error, :commit_error}
    end
  end

  def on_commit_result(_error) do
    {:error, :commit_error}
  end
end

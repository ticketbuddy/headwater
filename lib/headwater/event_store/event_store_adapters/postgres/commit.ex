defmodule Headwater.EventStoreAdapters.Postgres.Commit do
  require Logger
  alias Ecto.Multi
  alias Headwater.EventStoreAdapters.Postgres.{HeadwaterEventsSchema, HeadwaterIdempotencySchema}

  def add_idempotency(multi, idempotency_key) do
    multi
    |> Multi.insert(
      :idempotency_check,
      HeadwaterIdempotencySchema.changeset(%{idempotency_key: idempotency_key})
    )
  end

  def add_inserts(multi, {aggregate_id, latest_event_id, events}) do
    events
    |> Enum.with_index(1)
    |> Enum.reduce(multi, fn {event, index}, multi ->
      serialised_event = Headwater.EventStore.EventSerializer.serialize(event)

      multi
      |> Multi.insert(
        :"event_#{index}",
        fn %{idempotency_check: idempotency_check} ->
          %{
            event_id: latest_event_id + index,
            aggregate_id: aggregate_id,
            event: serialised_event,
            idempotency_id: idempotency_check.id
          }
          |> HeadwaterEventsSchema.changeset()
        end,
        returning: [:event_ref]
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

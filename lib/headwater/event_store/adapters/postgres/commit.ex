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

  def on_commit_result({:ok, change_data}) do
    # TODO: return list of Headwater.EventStore.RecordedEvent.t()
    IO.inspect(change_data, label: "change_data")

    :ok
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

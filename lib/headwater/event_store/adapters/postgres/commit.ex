defmodule Headwater.EventStore.Adapters.Postgres.Commit do
  require Logger
  alias Ecto.Multi
  alias Headwater.EventStore.RecordedEvent
  alias Headwater.EventStore.Adapters.Postgres.HeadwaterEventsSchema

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
    recorded_events =
      change_data
      |> Map.values()
      |> Enum.map(&RecordedEvent.new/1)
      |> Enum.sort(&(&1.event_number < &2.event_number))

    {:ok, recorded_events}
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

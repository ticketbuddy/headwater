defmodule Headwater.EventStore.Adapters.Postgres do
  defmacro __using__(repo: repo) do
    quote do
      @behaviour Headwater.EventStore
      @repo unquote(repo)
      alias Ecto.Multi

      require Logger

      alias Headwater.EventStore.Adapters.Postgres.{
        HeadwaterEventsSchema,
        HeadwaterEventBusSchema,
        HeadwaterIdempotencySchema,
        Commit
      }
      alias Headwater.EventStore.RecordedEvent

      @impl Headwater.EventStore
      def commit(persist_events, idempotency_key: idempotency_key) do
        Multi.new()
        |> Commit.add_idempotency(idempotency_key)
        |> Commit.add_inserts(persist_events)
        |> @repo.transaction()
        |> Commit.on_commit_result()
      end

      @impl Headwater.EventStore
      def load_events(aggregate_id) do
        Logger.log(:info, "fetching all events for aggregate #{aggregate_id}.")

        import Ecto.Query, only: [from: 2]

        recorded_events = from(event in HeadwaterEventsSchema,
          where: event.aggregate_id == ^aggregate_id,
          order_by: [asc: event.event_id]
        )
        |> @repo.all()
        |> Enum.map(&RecordedEvent.new/1)

        {:ok, recorded_events}
      end

      @impl Headwater.EventStore
      def has_wish_previously_succeeded?(idempotency_key) do
        @repo.get_by(HeadwaterIdempotencySchema, idempotency_key: idempotency_key)
        |> case do
          nil -> false
          _ -> true
        end
      end

      def get_next_event_ref(bus_id, base_event_ref) do
        import Ecto.Query, only: [from: 2]

        from(event in HeadwaterEventBusSchema,
          where: event.bus_id == ^bus_id,
          order_by: [desc: event.event_ref],
          limit: ^1
        )
        |> @repo.one()
        |> case do
          nil -> base_event_ref
          event -> Map.get(event, :event_ref)
        end
      end

      @impl Headwater.EventStore
      def bus_has_completed_event_ref(
            bus_id: bus_id,
            event_ref: event_ref
          ) do
        %{
          bus_id: bus_id,
          event_ref: event_ref
        }
        |> HeadwaterEventBusSchema.changeset()
        |> @repo.insert()
      end

      def get_event(event_ref) do
        @repo.get_by(HeadwaterEventsSchema, event_ref: event_ref)
        |> case do
          nil -> {:error, :event_not_found}
          event -> {:ok, RecordedEvent.new(event)}
        end
      end
    end
  end
end

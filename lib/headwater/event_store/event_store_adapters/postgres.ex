defmodule Headwater.EventStoreAdapters.Postgres do
  defmacro __using__(repo: repo) do
    quote do
      @behaviour Headwater.EventStore
      @repo unquote(repo)
      alias Ecto.Multi

      require Logger

      alias Headwater.EventStoreAdapters.Postgres.{
        HeadwaterEventsSchema,
        HeadwaterEventBusSchema,
        HeadwaterIdempotencySchema,
        Commit
      }

      @impl Headwater.EventStore
      def commit!(aggregate_id, last_event_id, events, idempotency_key) do
        Multi.new()
        |> Commit.add_idempotency(idempotency_key)
        |> Commit.add_inserts({aggregate_id, last_event_id, events})
        |> Commit.add_results()
        |> @repo.transaction()
        |> Commit.on_commit_result()
      end

      @impl Headwater.EventStore
      def load(aggregate_id) do
        {events, last_event_id} = fetch_events(aggregate_id)

        {:ok, events, last_event_id}
      end

      @impl Headwater.EventStore
      def read_events(from_event_ref: event_ref, limit: limit) do
        import Ecto.Query, only: [from: 2]

        from(event in HeadwaterEventsSchema,
          where: event.event_ref > ^event_ref,
          order_by: [asc: event.event_ref],
          limit: ^limit
        )
        |> @repo.all()
        |> serialise_events()
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

      defp fetch_events(aggregate_id) do
        Logger.log(:info, "fetching all events for aggregate #{aggregate_id}.")

        import Ecto.Query, only: [from: 2]

        from(event in HeadwaterEventsSchema,
          where: event.aggregate_id == ^aggregate_id,
          order_by: [asc: event.event_id]
        )
        |> @repo.all()
        |> format_events()
      end

      defp format_events(events) do
        serialised_events = serialise_events(events)

        {serialised_events, last_event_id(events)}
      end

      defp serialise_events(events) do
        Enum.map(events, fn event_schema ->
          Map.put(
            event_schema,
            :event,
            Headwater.EventStore.EventSerializer.deserialize(event_schema.event)
          )
        end)
      end

      defp last_event_id(events) when length(events) > 0 do
        List.last(events)
        |> Map.get(:event_id)
      end

      defp last_event_id(_events), do: 0
    end
  end
end

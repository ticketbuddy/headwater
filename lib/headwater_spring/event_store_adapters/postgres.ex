defmodule HeadwaterSpring.EventStoreAdapters.Postgres do
  defmacro __using__(repo: repo) do
    quote do
      @behaviour HeadwaterSpring.EventStore
      @repo unquote(repo)
      alias Ecto.Multi

      alias HeadwaterSpring.EventStoreAdapters.Postgres.{
        HeadwaterEventsSchema,
        HeadwaterEventBusSchema
      }

      @impl HeadwaterSpring.EventStore
      def commit!(stream_id, last_event_id, event, idempotency_key) do
        new_event_id = last_event_id + 1

        case insert_event(stream_id, event, new_event_id, idempotency_key) do
          {:ok, _} ->
            {:ok, new_event_id}

          error ->
            handle_insert_error!(error)
        end
      end

      defp insert_event(stream_id, event, latest_event_id, idempotency_key) do
        serialised_event = EventSerializer.serialize(event)

        %{
          event_id: latest_event_id,
          stream_id: stream_id,
          event: serialised_event,
          idempotency_key: idempotency_key
        }
        |> HeadwaterEventsSchema.changeset()
        |> @repo.insert()
      end

      defp handle_insert_error!({:error, %Ecto.Changeset{errors: errors}}) do
        case Keyword.has_key?(errors, :wish_already_completed) do
          true -> {:error, :wish_already_completed}
          false -> out_of_sync!
        end
      end

      defp handle_insert_error!(_) do
        out_of_sync!
      end

      defp out_of_sync! do
        raise "Out of sync with database, crashing to reload"
      end

      @impl HeadwaterSpring.EventStore
      def load(stream_id) do
        {events, last_event_id} = fetch_events(stream_id)

        {:ok, events, last_event_id}
      end

      @impl HeadwaterSpring.EventStore
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

      @impl HeadwaterSpring.EventStore
      def has_wish_previously_succeeded?(idempotency_key) do
        @repo.get_by(HeadwaterEventsSchema, idempotency_key: idempotency_key)
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

      @impl HeadwaterSpring.EventStore
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

      defp fetch_events(stream_id) do
        import Ecto.Query, only: [from: 2]

        from(event in HeadwaterEventsSchema,
          where: event.stream_id == ^stream_id,
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
            EventSerializer.deserialize(event_schema.event)
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

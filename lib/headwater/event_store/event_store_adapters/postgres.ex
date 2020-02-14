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
        HeadwaterIdempotencySchema
      }

      @impl Headwater.EventStore
      def commit!(aggregate_id, last_event_id, events, idempotency_key) do
        new_event_id = last_event_id + Enum.count(events)

        case insert_events(aggregate_id, events, new_event_id, idempotency_key) do
          {:ok, _} ->
            Logger.log(
              :info,
              "committed #{Enum.count(events)} events on aggregate: #{aggregate_id}"
            )

            {:ok, new_event_id}

          error ->
            Logger.log(:error, "commit error: #{inspect(error)}")
            handle_insert_error!(error)
        end
      end

      defp insert_events(aggregate_id, events, latest_event_id, idempotency_key) do
        events = List.wrap(events)

        multi_with_idempotency =
          Multi.new()
          |> Multi.insert(
            :idempotency_check,
            HeadwaterIdempotencySchema.changeset(%{idempotency_key: idempotency_key})
          )

        events
        |> Enum.with_index()
        |> Enum.reduce(multi_with_idempotency, fn {event, index}, multi ->
          serialised_event = Headwater.EventStore.EventSerializer.serialize(event)
          event_id = latest_event_id + index

          multi
          |> Multi.insert(:"event_#{event_id}", fn %{idempotency_check: idempotency_check} ->
            %{
              event_id: event_id + index,
              aggregate_id: aggregate_id,
              event: serialised_event,
              idempotency_id: idempotency_check.id
            }
            |> HeadwaterEventsSchema.changeset()
          end)
        end)
        |> @repo.transaction()
      end

      defp handle_insert_error!({:error, error = %Ecto.Changeset{errors: errors}}) do
        case Keyword.has_key?(errors, :wish_already_completed) do
          true ->
            Logger.log(:info, "wish already completed.")
            {:error, :wish_already_completed}

          false ->
            Logger.log(:error, "Insert changeset error: #{inspect(error)}")
            out_of_sync!
        end
      end

      defp handle_insert_error!(error) do
        Logger.log(:error, "insert error #{inspect(error)}")
        out_of_sync!
      end

      defp out_of_sync! do
        raise "Out of sync with database, crashing to reload"
      end

      @impl Headwater.EventStore
      def load(aggregate_id) do
        {events, last_event_id} = fetch_events(aggregate_id)

        {:ok, events, last_event_id}
      end

      @impl Headwater.EventStore
      def read_events(from_event_ref: event_ref, limit: limit) do
        Logger.log(:info, "fetching next #{limit} events from event_ref #{event_ref}.")

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

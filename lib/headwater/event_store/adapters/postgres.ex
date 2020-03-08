defmodule Headwater.EventStore.Adapters.Postgres do
  defmacro __using__(repo: repo) do
    quote do
      @behaviour Headwater.EventStore
      @repo unquote(repo)
      alias Ecto.Multi
      @read_batch 100

      require Logger

      alias Headwater.EventStore.Adapters.Postgres.{
        HeadwaterEventsSchema,
        HeadwaterEventBusSchema,
        Commit
      }

      alias Headwater.EventStore.RecordedEvent

      @impl Headwater.EventStore
      def commit(persist_events) do
        Multi.new()
        |> Commit.add_inserts(persist_events)
        |> @repo.transaction()
        |> Commit.on_commit_result()
      end

      @impl Headwater.EventStore
      def load_events(aggregate_id, from_event \\ 0) do
        recorded_events_stream = stream_events(aggregate_id, from_event)

        {:ok, recorded_events_stream}
      end

      defp stream_events(aggregate_id, from_event_number) do
        Elixir.Stream.resource(
          fn -> from_event_number end,
          fn next_event_number ->
            case read_and_decode_events(aggregate_id, next_event_number) do
              {:ok, []} -> {:halt, next_event_number}
              {:ok, events} -> {events, next_event_number + length(events)}
            end
          end,
          fn _ -> :ok end
        )
      end

      defp read_and_decode_events(aggregate_id, from_event_number) do
        case read_events_from_db(aggregate_id, from_event_number) do
          {:ok, recorded_events} ->
            deserialized_events = recorded_events |> Enum.map(&RecordedEvent.new/1)

            {:ok, deserialized_events}

          {:error, _error} = reply ->
            reply
        end
      end

      defp read_events_from_db(aggregate_id, from_event_number) do
        import Ecto.Query, only: [from: 2]

        bare_events =
          from(event in HeadwaterEventsSchema,
            where:
              event.aggregate_id == ^aggregate_id and event.event_number > ^from_event_number,
            order_by: [asc: event.event_number],
            limit: @read_batch
          )
          |> @repo.all()

        {:ok, bare_events}
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

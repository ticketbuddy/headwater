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
        Commit,
        Query,
        ReadStream
      }

      alias Headwater.EventStore.RecordedEvent

      @impl Headwater.EventStore
      def commit(persist_events) do
        Logger.info(fn -> "Commiting #{Enum.count(persist_events)} recorded events." end)

        Commit.start()
        |> Commit.add_inserts(persist_events)
        |> @repo.transaction()
        |> Commit.on_commit_result()
      end

      @impl Headwater.EventStore
      def load_events(starting_event_number \\ 0) do
        Logger.info(fn -> "Loading events from #{starting_event_number}." end)

        recorded_events_stream =
          ReadStream.read(
            fn next_event_number ->
              Query.recorded_events(from_event_number: next_event_number)
              |> execute__and_decode_events()
            end,
            starting_event_number: starting_event_number
          )

        {:ok, recorded_events_stream}
      end

      @impl Headwater.EventStore
      def load_events_for_aggregate(aggregate_id, starting_event_number \\ 0) do
        Logger.info(fn ->
          "Loading events for aggregate #{aggregate_id} from #{starting_event_number}."
        end)

        recorded_events_stream =
          ReadStream.read(
            fn next_event_number ->
              Query.recorded_events(aggregate_id, from_event_number: next_event_number)
              |> execute__and_decode_events()
            end,
            starting_event_number: starting_event_number
          )

        {:ok, recorded_events_stream}
      end

      defp execute__and_decode_events(query) do
        deserialized_events =
          query
          |> @repo.all()
          |> Enum.map(&RecordedEvent.new/1)

        {:ok, deserialized_events}
      end

      def get_bus_next_event_number(bus_id, base_event_ref) do
        Query.event_bus_next_event_number(bus_id)
        |> @repo.one()
        |> case do
          nil ->
            Logger.info("Using base event ref #{base_event_ref} for bus #{bus_id}.")

            base_event_ref

          event ->
            Logger.info("Continuing from event_number #{event.event_ref} for bus #{bus_id}.")
            Map.get(event, :event_ref)
        end
      end

      @impl Headwater.EventStore
      def bus_has_completed_event_number(
            bus_id: bus_id,
            event_number: event_ref
          ) do
        Logger.info("Recording listener #{bus_id} has completed event_number #{event_ref}.")

        %{
          bus_id: bus_id,
          event_ref: event_ref
        }
        |> HeadwaterEventBusSchema.changeset()
        |> @repo.insert()
      end
    end
  end
end

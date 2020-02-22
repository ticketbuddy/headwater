defmodule Headwater.EventStore.Adapters.Postgres.CommitTest do
  use ExUnit.Case
  alias Ecto.Multi
  alias Headwater.EventStore.{PersistEvent, RecordedEvent}
  alias Headwater.EventStore.Adapters.Postgres.Commit
  alias Headwater.EventStore.Adapters.Postgres.HeadwaterIdempotencySchema

  describe "add inserting a list of events for persistence" do
    test "adds the instructions to a multi" do
      persist_events = [
        %PersistEvent{
          data: "{}",
          aggregate_id: "fake-agg-one",
          aggregate_number: 2,
          idempotency_key: "idempo-45345"
        },
        %PersistEvent{
          data: "{}",
          aggregate_id: "fake-agg-one",
          aggregate_number: 3,
          idempotency_key: "idempo-45345"
        },
        %PersistEvent{
          data: "{}",
          aggregate_id: "fake-agg-one",
          aggregate_number: 4,
          idempotency_key: "idempo-45345"
        }
      ]

      multi_result = Commit.add_inserts(Multi.new(), persist_events)

      assert [
               event_2:
                 {:insert,
                  %Ecto.Changeset{
                    action: :insert,
                    changes: %{aggregate_id: "fake-agg-one", aggregate_number: 2, data: "{}"},
                    errors: [],
                    data: %Headwater.EventStore.Adapters.Postgres.HeadwaterEventsSchema{},
                    valid?: true
                  }, [returning: [:event_id, :event_number]]},
               event_3:
                 {:insert,
                  %Ecto.Changeset{
                    action: :insert,
                    changes: %{aggregate_id: "fake-agg-one", aggregate_number: 3, data: "{}"},
                    errors: [],
                    data: %Headwater.EventStore.Adapters.Postgres.HeadwaterEventsSchema{},
                    valid?: true
                  }, [returning: [:event_id, :event_number]]},
               event_4:
                 {:insert,
                  %Ecto.Changeset{
                    action: :insert,
                    changes: %{aggregate_id: "fake-agg-one", aggregate_number: 4, data: "{}"},
                    errors: [],
                    data: %Headwater.EventStore.Adapters.Postgres.HeadwaterEventsSchema{},
                    valid?: true
                  }, [returning: [:event_id, :event_number]]}
             ] = Multi.to_list(multi_result)
    end
  end

  describe "Commit.on_commit_result/1" do
    defmodule Event do
      defstruct [:counter_id, :value]
    end

    test "when idempotency check fails" do
      changes = %{}
      error_changeset = %Ecto.Changeset{errors: [wish_already_completed: %{some: "reason"}]}

      assert {:error, :wish_already_completed} ==
               Commit.on_commit_result({:error, :idempotency_check, error_changeset, changes})
    end

    test "when commit fails with different changeset errors" do
      changes = %{}
      error_changeset = %Ecto.Changeset{errors: [something_else: %{some: "reason"}]}

      assert {:error, :commit_error} ==
               Commit.on_commit_result({:error, :idempotency_check, error_changeset, changes})
    end

    test "when commit fails not with changeset error" do
      assert {:error, :commit_error} == Commit.on_commit_result({:error, :too_much_lemonade})
    end

    test "when commit is successful, orders recorded events by event_number" do
      change_data = %{
        event_1: %Headwater.EventStore.Adapters.Postgres.HeadwaterEventsSchema{
          aggregate_id: "abc",
          aggregate_number: 2,
          data:
            "{\"__struct__\":\"Elixir.Headwater.EventStore.Adapters.Postgres.CommitTest.Event\",\"counter_id\":\"abc\",\"value\":5}",
          event_id: "7d5c19fc-1f48-4db4-a222-302c951869f6",
          event_number: 2,
          idempotency_key: "2d9e90ea88524b45bd1988eb735ea2b4",
          inserted_at: ~U[2020-02-22 19:09:35Z],
          updated_at: ~U[2020-02-22 19:09:35Z]
        },
        event_2: %Headwater.EventStore.Adapters.Postgres.HeadwaterEventsSchema{
          aggregate_id: "abc",
          aggregate_number: 1,
          data:
            "{\"__struct__\":\"Elixir.Headwater.EventStore.Adapters.Postgres.CommitTest.Event\",\"counter_id\":\"abc\",\"value\":7}",
          event_id: "83005289-033b-479c-8903-10639904f494",
          event_number: 1,
          idempotency_key: "2d9e90ea88524b45bd1988eb735ea2b4",
          inserted_at: ~U[2020-02-22 19:09:35Z],
          updated_at: ~U[2020-02-22 19:09:35Z]
        }
      }

      assert {:ok,
              [
                %RecordedEvent{
                  aggregate_id: "abc",
                  event_id: "83005289-033b-479c-8903-10639904f494",
                  idempotency_key: "2d9e90ea88524b45bd1988eb735ea2b4",
                  event_number: 1,
                  aggregate_number: 1,
                  data: %Headwater.EventStore.Adapters.Postgres.CommitTest.Event{
                    counter_id: "abc",
                    value: 7
                  },
                  created_at: ~U[2020-02-22 19:09:35Z]
                },
                %RecordedEvent{
                  aggregate_id: "abc",
                  event_id: "7d5c19fc-1f48-4db4-a222-302c951869f6",
                  idempotency_key: "2d9e90ea88524b45bd1988eb735ea2b4",
                  event_number: 2,
                  aggregate_number: 2,
                  data: %Headwater.EventStore.Adapters.Postgres.CommitTest.Event{
                    counter_id: "abc",
                    value: 5
                  },
                  created_at: ~U[2020-02-22 19:09:35Z]
                }
              ]} == Commit.on_commit_result({:ok, change_data})
    end
  end
end

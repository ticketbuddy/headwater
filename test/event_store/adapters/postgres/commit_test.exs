defmodule Headwater.EventStore.Adapters.Postgres.CommitTest do
  use ExUnit.Case
  alias Ecto.Multi
  alias Headwater.EventStore.PersistEvent
  alias Headwater.EventStore.Adapters.Postgres.Commit
  alias Headwater.EventStore.Adapters.Postgres.HeadwaterIdempotencySchema

  describe "Commit.add_idempotency/2" do
    test "adds idempotency check to a multi" do
      idempotency_key = "idempo-12345"

      multi_result = Commit.add_idempotency(Multi.new(), idempotency_key)

      assert [
               idempotency_check:
                 {:insert,
                  %Ecto.Changeset{
                    action: :insert,
                    changes: %{idempotency_key: "idempo-12345"},
                    errors: [],
                    data: %HeadwaterIdempotencySchema{},
                    valid?: true
                  }, []}
             ] = Multi.to_list(multi_result)
    end
  end

  describe "add inserting a list of events for persistence" do
    test "adds the instructions to a multi" do
      persist_events = [
        %PersistEvent{
          data: "{}",
          aggregate_id: "fake-agg-one",
          aggregate_number: 2
        },
        %PersistEvent{
          data: "{}",
          aggregate_id: "fake-agg-one",
          aggregate_number: 3
        },
        %PersistEvent{
          data: "{}",
          aggregate_id: "fake-agg-one",
          aggregate_number: 4
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
  end
end

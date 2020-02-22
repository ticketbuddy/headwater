defmodule Headwater.EventStore.Adapters.Postgres.HeadwaterEventsSchema do
  use Ecto.Schema
  @primary_key {:event_id, :binary_id, autogenerate: true}
  @timestamps_opts [type: :utc_datetime]

  alias Headwater.EventStore.PersistEvent

  schema "headwater_events" do
    field(:aggregate_id, :string)
    field(:event_number, :integer)
    field(:aggregate_number, :integer)
    field(:idempotency_key, :string)
    field(:data, :string)

    timestamps()
  end

  def changeset(persist_event = %PersistEvent{}) do
    import Ecto.Changeset
    params = Map.from_struct(persist_event)

    %__MODULE__{}
    |> cast(params, [:data, :aggregate_id, :aggregate_number, :idempotency_key])
    |> validate_required([:data, :aggregate_id, :aggregate_number, :idempotency_key])
    |> unique_constraint(:out_of_sync_with_event_store,
      name: :headwater_events_aggregate_id_event_id_index
    )
  end
end

defmodule Headwater.EventStoreAdapters.Postgres.HeadwaterEventsSchema do
  use Ecto.Schema
  @primary_key false
  @timestamps_opts [type: :utc_datetime]

  schema "headwater_events" do
    field(:event, :string)
    field(:event_id, :integer, primary_key: true)
    field(:aggregate_id, :string, primary_key: true)
    field(:event_ref, :integer)
    field(:idempotency_id, :binary)

    timestamps()
  end

  def changeset(params) do
    import Ecto.Changeset

    %__MODULE__{}
    |> cast(params, [:event, :event_id, :aggregate_id, :idempotency_id])
    |> validate_required([:event, :event_id, :aggregate_id, :idempotency_id])
    |> unique_constraint(:out_of_sync_with_event_store,
      name: :headwater_events_aggregate_id_event_id_index
    )
  end
end

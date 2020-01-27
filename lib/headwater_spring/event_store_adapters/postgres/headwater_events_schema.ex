defmodule HeadwaterSpring.EventStoreAdapters.Postgres.HeadwaterEventsSchema do
  use Ecto.Schema
  @primary_key false
  @timestamps_opts [type: :utc_datetime]

  schema "headwater_events" do
    field(:event, :string)
    field(:event_id, :integer, primary_key: true)
    field(:stream_id, :string, primary_key: true)
    field(:event_ref, :integer)
    field(:idempotency_key, :string)

    timestamps()
  end

  def changeset(params) do
    import Ecto.Changeset

    %__MODULE__{}
    |> cast(params, [:event, :event_id, :stream_id, :idempotency_key])
    |> validate_required([:event, :event_id, :stream_id, :idempotency_key])
    |> unique_constraint(:out_of_sync_with_event_store,
      name: :headwater_events_stream_id_event_id_index
    )
    |> unique_constraint(:wish_already_completed,
      name: :headwater_events_idempotency_key_index
    )
  end
end

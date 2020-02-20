defmodule Headwater.EventStore.Adapters.Postgres.HeadwaterIdempotencySchema do
  use Ecto.Schema
  @primary_key {:id, :binary_id, autogenerate: true}
  @timestamps_opts [type: :utc_datetime]

  schema "headwater_idempotency" do
    field(:idempotency_key, :string)
  end

  def changeset(params) do
    import Ecto.Changeset

    %__MODULE__{}
    |> cast(params, [:idempotency_key])
    |> validate_required([:idempotency_key])
    |> unique_constraint(:wish_already_completed,
      name: :headwater_idempotency_idempotency_key_index
    )
  end
end

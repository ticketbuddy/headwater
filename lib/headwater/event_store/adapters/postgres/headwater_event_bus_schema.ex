defmodule Headwater.EventStore.Adapters.Postgres.HeadwaterEventBusSchema do
  use Ecto.Schema
  @primary_key false
  @timestamps_opts [type: :utc_datetime]

  schema "headwater_event_bus" do
    field(:bus_id, :string, primary_key: true)
    field(:event_ref, :integer)
  end

  def changeset(params) do
    import Ecto.Changeset

    %__MODULE__{}
    |> cast(params, [:bus_id, :event_ref])
    |> validate_required([:bus_id, :event_ref])
    |> unique_constraint(:bus_id, name: :bus_id)
  end
end

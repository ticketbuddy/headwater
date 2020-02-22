defmodule Headwater.EventStore.Adapters.Postgres.Migration.HeadwaterEvents do
  use Ecto.Migration

  def change do
    create table("headwater_events") do
      add(:event_id, :uuid, primary_key: true, null: false)
      add(:aggregate_id, :string, null: false)
      add(:event_number, :bigserial)
      add(:aggregate_number, :integer, null: false)
      add(:data, :text, null: false)
      add(:idempotency_key, :binary, null: false)

      timestamps()
    end
  end
end

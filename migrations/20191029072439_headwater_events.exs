defmodule Headwater.Migrations.HeadwaterEvents do
  use Ecto.Migration

  def change do
    create table("headwater_events") do
      add(:event_ref, :bigserial, primary_key: true, null: false)
      add(:aggregate_id, :string, null: false)
      add(:event_id, :integer, null: false)
      add(:event, :text, null: false)
      add(:idempotency_key, :binary, null: false)

      timestamps()
    end
  end
end

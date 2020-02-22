defmodule Example.Repo.Migrations.HeadwaterEvents do
  use Ecto.Migration

  def change do
    create table("headwater_events", primary_key: false) do
      add(:event_id, :uuid, primary_key: true)
      add(:aggregate_id, :string, null: false)
      add(:event_number, :bigserial, null: false)
      add(:aggregate_number, :bigserial, null: false)
      add(:data, :text, null: false)
      add(:idempotency_key, :binary, null: false)

      timestamps()
    end
  end
end

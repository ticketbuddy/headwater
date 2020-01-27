defmodule Example.Repo.Migrations.HeadwaterEvents do
  use Ecto.Migration

  def change do
    create table("headwater_events") do
      add(:event_id, :integer, primary_key: true, null: false)
      add(:stream_id, :string, primary_key: true, null: false)
      add(:event_ref, :bigserial, null: false)
      add(:event, :text, null: false)
      add(:idempotency_key, :string, null: false)

      timestamps()
    end

    create unique_index("headwater_events", [:idempotency_key])
    create unique_index("headwater_events", [:stream_id, :event_id])
  end
end

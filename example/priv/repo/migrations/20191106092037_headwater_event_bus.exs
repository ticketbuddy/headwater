defmodule Example.Repo.Migrations.HeadwaterEventBus do
  use Ecto.Migration

  def change do
    create table("headwater_event_bus") do
      add(:bus_id, :string, primary_key: true, null: false)
      add(:event_ref, :bigserial, null: false)
    end
  end
end

defmodule Headwater.EventStore.Adapters.Postgres.Migration.HeadwaterEventBus do
  use Ecto.Migration

  def change do
    create table("headwater_event_bus") do
      add(:bus_id, :string, null: false)
      add(:event_ref, :integer, null: false)
    end
  end
end

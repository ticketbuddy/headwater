defmodule Example.Repo.Migrations.HeadwaterIdempotency do
  use Ecto.Migration

  def change do
    create table("headwater_idempotency", primary_key: false) do
      add :id, :uuid, primary_key: true
      add(:idempotency_key, :string, null: false)
    end

    create unique_index("headwater_idempotency", [:idempotency_key])
  end
end

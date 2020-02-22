defmodule Example.Repo.Migrations.HeadwaterEvents do
  use Ecto.Migration

  def change do
    Headwater.EventStore.Adapters.Postgres.Migration.HeadwaterEvents.change()
  end
end

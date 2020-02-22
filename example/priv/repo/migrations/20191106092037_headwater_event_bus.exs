defmodule Example.Repo.Migrations.HeadwaterEventBus do
  use Ecto.Migration

  def change do
    Headwater.EventStore.Adapters.Postgres.Migration.HeadwaterEventBus.change()
  end
end

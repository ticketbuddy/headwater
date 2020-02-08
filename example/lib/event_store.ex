defmodule Example.EventStore do
  use Headwater.EventStoreAdapters.Postgres, repo: Example.Repo
end

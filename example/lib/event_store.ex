defmodule Example.EventStore do
  use HeadwaterSpring.EventStoreAdapters.Postgres, repo: Example.Repo
end

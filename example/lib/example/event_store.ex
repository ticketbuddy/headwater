defmodule Example.EventStore do
  use Headwater.EventStore.Adapters.Postgres, repo: Example.Repo
end

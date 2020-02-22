import Mix.Config

config :example, ecto_repos: [Example.Repo]

config :example, Example.Repo, migration_timestamps: [type: :utc_datetime]

import_config "#{Mix.env()}.exs"

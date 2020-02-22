import Mix.Config

config :logger, level: :warn

config :example, Example.Repo,
  username: "postgres",
  password: "postgres",
  database: "headwater_example_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

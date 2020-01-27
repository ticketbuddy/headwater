import Mix.Config

config :example, Example.Repo,
  username: "postgres",
  password: "postgres",
  database: "headwater_spring_example_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

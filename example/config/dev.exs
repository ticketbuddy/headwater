import Mix.Config

config :logger, level: :info

config :headwater,
  supervisor: Example.AggregateSupervisor,
  registry: Example.Registry

config :example, Example.Repo,
  username: "postgres",
  password: "postgres",
  database: "headwater_example_dev",
  hostname: "localhost",
  log: false

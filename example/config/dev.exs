import Mix.Config

config :headwater_spring,
  supervisor: Example.StreamSupervisor,
  registry: Example.Registry

config :example, Example.Repo,
  username: "postgres",
  password: "postgres",
  database: "headwater_spring_example_dev",
  hostname: "localhost"

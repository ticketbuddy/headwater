defmodule Example.Application do
  use Application

  def start(_type, _args) do
    children =
      [
        Example.Repo,
        {Registry, keys: :unique, name: Example.Registry},
        {DynamicSupervisor, name: Example.StreamSupervisor, strategy: :one_for_one}
      ] ++ ExampleListener.children()

    Supervisor.start_link(children, name: Example.Supervisor, strategy: :one_for_one)
  end
end

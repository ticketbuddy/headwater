defmodule Example.Test.Support.Helper do
  def persist do
    quote do
      setup tags do
        :ok = Ecto.Adapters.SQL.Sandbox.checkout(Example.Repo)

        unless tags[:async] do
          Ecto.Adapters.SQL.Sandbox.mode(
            Example.Repo,
            {:shared, self()}
          )
        end

        :ok
      end
    end
  end

  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end

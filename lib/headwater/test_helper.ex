defmodule Headwater.TestHelper do
  defmacro __using__(event_store_repo: event_store_repo) do
    quote do
      setup tags do
        :ok = Ecto.Adapters.SQL.Sandbox.checkout(unquote(event_store_repo))

        unless tags[:async] do
          Ecto.Adapters.SQL.Sandbox.mode(
            unquote(event_store_repo),
            {:shared, self()}
          )
        end

        :ok
      end
    end
  end
end

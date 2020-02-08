defmodule Headwater.Spring.Router do
  defmacro __using__(spring: spring) do
    quote do
      @spring unquote(spring)
      import Headwater.Spring.Router, only: [defaction: 2, defread: 2]
    end
  end

  alias Headwater.Spring.{WriteRequest, ReadRequest}

  defmacro defaction(action, to: aggregate, by_key: key) when is_atom(action) do
    quote do
      def unquote(action)(wish, opts \\ []) do
        %WriteRequest{
          aggregate_id: Map.get(wish, unquote(key)),
          handler: unquote(aggregate),
          wish: wish,
          idempotency_key: Keyword.get(opts, :idempotency_key, Headwater.Spring.uuid())
        }
        |> @spring.handle()
      end
    end
  end

  defmacro defread(read, to: aggregate) when is_atom(read) do
    quote do
      def unquote(read)(aggregate_id) do
        %ReadRequest{
          aggregate_id: aggregate_id,
          handler: unquote(aggregate)
        }
        |> @spring.read_state()
      end
    end
  end
end

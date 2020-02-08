defmodule Headwater.Aggregate.Router do
  defmacro __using__(aggregate: aggregate) do
    quote do
      @aggregate unquote(aggregate)
      import Headwater.Aggregate.Router, only: [defaction: 2, defread: 2]
    end
  end

  alias Headwater.Aggregate.{WriteRequest, ReadRequest}

  defmacro defaction(action, to: aggregate, by_key: key) when is_atom(action) do
    quote do
      def unquote(action)(wish, opts \\ []) do
        %WriteRequest{
          aggregate_id: Map.get(wish, unquote(key)),
          handler: unquote(aggregate),
          wish: wish,
          idempotency_key: Keyword.get(opts, :idempotency_key, Headwater.Aggregate.uuid())
        }
        |> @aggregate.handle()
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
        |> @aggregate.read_state()
      end
    end
  end
end

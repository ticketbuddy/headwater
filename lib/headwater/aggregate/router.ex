defmodule Headwater.Aggregate.Router do
  defmacro __using__(aggregate_directory: aggregate_directory) do
    quote do
      @aggregate_directory unquote(aggregate_directory)
      import Headwater.Aggregate.Router, only: [defaction: 2, defread: 2]
    end
  end

  alias Headwater.AggregateDirectory.{WriteRequest, ReadRequest}

  defmacro defaction(action, to: handler, by_key: key) when is_atom(action) do
    quote do
      def unquote(action)(wish, opts \\ []) do
        %WriteRequest{
          aggregate_id: Map.get(wish, unquote(key)),
          handler: unquote(handler),
          wish: wish,
          idempotency_key: Keyword.get(opts, :idempotency_key, Headwater.uuid())
        }
        |> @aggregate_directory.handle()
      end
    end
  end

  defmacro defread(read, to: handler) when is_atom(read) do
    quote do
      def unquote(read)(aggregate_id) do
        %ReadRequest{
          aggregate_id: aggregate_id,
          handler: unquote(handler)
        }
        |> @aggregate_directory.read_state()
      end
    end
  end
end

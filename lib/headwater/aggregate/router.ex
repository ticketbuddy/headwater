defmodule Headwater.Aggregate.Router do
  alias Headwater.Aggregate.Wish
  alias Headwater.Aggregate.Directory.{WriteRequest, ReadRequest}

  defmacro __using__(config: config) do
    quote do
      alias Headwater.Aggregate.Directory.{ReadRequest, WriteRequest}
      @config unquote(config)
      import Headwater.Aggregate.Router, only: [defread: 2]

      def handle(wish, opts \\ []) do
        aggregate_id = Wish.aggregate_id(wish)
        aggregate_handler = Wish.aggregate_handler(wish)

        write_request = %WriteRequest{
          aggregate_id: aggregate_handler.aggregate_prefix() <> aggregate_id,
          handler: aggregate_handler,
          wish: wish,
          idempotency_key: Keyword.get(opts, :idempotency_key, Headwater.uuid())
        }

        @config.directory.handle(write_request, @config)
      end

      defp config do
        @config
        |> Map.put(:router, __MODULE__)
      end
    end
  end

  defmacro defread(read, to: handler) when is_atom(read) do
    quote do
      def unquote(read)(aggregate_id) do
        read_request = %ReadRequest{
          aggregate_id: unquote(handler).aggregate_prefix <> aggregate_id,
          handler: unquote(handler)
        }

        @config.directory.handle(read_request, @config)
      end
    end
  end
end

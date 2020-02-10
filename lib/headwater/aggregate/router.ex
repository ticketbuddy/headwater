defmodule Headwater.Aggregate.Router do
  defmacro __using__(aggregate_directory: aggregate_directory) do
    quote do
      @aggregate_directory unquote(aggregate_directory)
      import Headwater.Aggregate.Router, only: [defaction: 2, defread: 2]
    end
  end

  alias Headwater.AggregateDirectory.{WriteRequest, ReadRequest}

  defmacro defaction(action, action_opts) when is_atom(action) do
    handler = Keyword.get(action_opts, :to)
    key = Keyword.get(action_opts, :by_key)

    unless handler && key do
      raise ":to and :by_key must be given as options"
    end

    quote do
      def unquote(action)(wish, opts \\ []) do
        prefix = Keyword.get(unquote(action_opts), :with_prefix, "")

        %WriteRequest{
          aggregate_id: prefix <> Map.get(wish, unquote(key)),
          handler: unquote(handler),
          wish: wish,
          idempotency_key: Keyword.get(opts, :idempotency_key, Headwater.uuid())
        }
        |> @aggregate_directory.handle()
      end
    end
  end

  defmacro defread(read, read_opts) when is_atom(read) do
    handler = Keyword.get(read_opts, :to)

    unless handler do
      raise ":to must be given as options"
    end

    quote do
      def unquote(read)(aggregate_id) do
        prefix = Keyword.get(unquote(read_opts), :with_prefix, "")

        %ReadRequest{
          aggregate_id: prefix <> aggregate_id,
          handler: unquote(handler)
        }
        |> @aggregate_directory.read_state()
      end
    end
  end
end

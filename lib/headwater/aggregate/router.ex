defmodule Headwater.Aggregate.Router do
  defmacro __using__(aggregate_directory: aggregate_directory) do
    quote do
      @aggregate_directory unquote(aggregate_directory)
      import Headwater.Aggregate.Router, only: [defaction: 2, defread: 2]
    end
  end

  alias Headwater.AggregateDirectory.{WriteRequest, ReadRequest}

  defmacro defaction(wish_module_or_modules, to: handler, by_key: key) do
    wish_module_or_modules
    |> List.wrap()
    |> Enum.map(fn wish_module ->
      quote do
        def handle(wish = %unquote(wish_module){}), do: do_handle(wish, [])
        def handle(wish = %unquote(wish_module){}, opts), do: do_handle(wish, opts)

        defp do_handle(wish = %unquote(wish_module){}, opts) do
          %WriteRequest{
            aggregate_id: unquote(handler).aggregate_prefix <> Map.get(wish, unquote(key)),
            handler: unquote(handler),
            wish: wish,
            idempotency_key: Keyword.get(opts, :idempotency_key, Headwater.uuid())
          }
          |> @aggregate_directory.handle()
        end
      end
    end)
  end

  defmacro defread(read, to: handler) when is_atom(read) do
    quote do
      def unquote(read)(aggregate_id) do
        %ReadRequest{
          aggregate_id: unquote(handler).aggregate_prefix <> aggregate_id,
          handler: unquote(handler)
        }
        |> @aggregate_directory.read_state()
      end
    end
  end
end

defmodule HeadwaterSpring.Router do
  defmacro __using__(spring: spring) do
    quote do
      @spring unquote(spring)
      import HeadwaterSpring.Router, only: [defaction: 2, defread: 2]
    end
  end

  alias HeadwaterSpring.{WriteRequest, ReadRequest}

  defmacro defaction(action, to: stream, by_key: key) when is_atom(action) do
    quote do
      def unquote(action)(wish, opts \\ []) do
        %WriteRequest{
          stream_id: Map.get(wish, unquote(key)),
          handler: unquote(stream),
          wish: wish,
          idempotency_key: Keyword.get(opts, :idempotency_key, HeadwaterSpring.uuid())
        }
        |> @spring.handle()
      end
    end
  end

  defmacro defread(read, to: stream) when is_atom(read) do
    quote do
      def unquote(read)(stream_id) do
        %ReadRequest{
          stream_id: stream_id,
          handler: unquote(stream)
        }
        |> @spring.read_state()
      end
    end
  end
end

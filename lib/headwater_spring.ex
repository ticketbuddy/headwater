defmodule HeadwaterSpring do
  defmodule Request do
    @enforce_keys [:stream_id, :handler, :wish, :idempotency_key]
    defstruct @enforce_keys
  end

  def uuid do
    UUID.uuid4(:hex)
  end

  defmacro __using__(registry: registry, supervisor: supervisor, event_store: event_store) do
    quote do
      @registry unquote(registry)
      @supervisor unquote(supervisor)
      @event_store unquote(event_store)

      def handle(request = %Request{}) do
        %HeadwaterSpring.Stream{
          id: request.stream_id,
          handler: request.handler,
          registry: @registry,
          supervisor: @supervisor,
          event_store: @event_store
        }
        |> ensure_started()
        |> HeadwaterSpring.Stream.propose_wish(request.wish, request.idempotency_key)
      end

      defp ensure_started(stream) do
        HeadwaterSpring.Stream.new(stream)

        stream
      end
    end
  end
end

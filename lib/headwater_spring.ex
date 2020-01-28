defmodule HeadwaterSpring do
  defmodule WriteRequest do
    @enforce_keys [:stream_id, :handler, :wish, :idempotency_key]
    defstruct @enforce_keys
  end

  defmodule ReadRequest do
    @enforce_keys [:stream_id, :handler]
    defstruct @enforce_keys
  end

  defmodule Result do
    @enforce_keys [:latest_event_id, :state]
    defstruct @enforce_keys

    def new({:ok, {latest_event_id, state}}) do
      {:ok,
       %Result{
         latest_event_id: latest_event_id,
         state: state
       }}
    end

    # def new({:error, :execute, response}) do
    #   {:error, response}
    # end
    #
    # def new({:error, :next_state, response}) do
    #
    # end
  end

  def uuid do
    UUID.uuid4(:hex)
  end

  defmacro __using__(registry: registry, supervisor: supervisor, event_store: event_store) do
    quote do
      @registry unquote(registry)
      @supervisor unquote(supervisor)
      @event_store unquote(event_store)

      def handle(request = %WriteRequest{}) do
        %HeadwaterSpring.Stream{
          id: request.stream_id,
          handler: request.handler,
          registry: @registry,
          supervisor: @supervisor,
          event_store: @event_store
        }
        |> ensure_started()
        |> HeadwaterSpring.Stream.propose_wish(request.wish, request.idempotency_key)
        |> HeadwaterSpring.Result.new()
      end

      def read_state(request = %ReadRequest{}) do
        %HeadwaterSpring.Stream{
          id: request.stream_id,
          handler: request.handler,
          registry: @registry,
          supervisor: @supervisor,
          event_store: @event_store
        }
        |> ensure_started()
        |> HeadwaterSpring.Stream.current_state()
        |> HeadwaterSpring.Result.new()
      end

      defp ensure_started(stream) do
        HeadwaterSpring.Stream.new(stream)

        stream
      end
    end
  end
end

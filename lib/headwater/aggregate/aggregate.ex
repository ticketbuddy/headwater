defmodule Headwater.Aggregate do
  @callback handle(WriteRequest.t()) :: {:ok, Result.t()}
  @callback read_state(ReadRequest.t()) :: {:ok, Result.t()}

  defmodule WriteRequest do
    @enforce_keys [:aggregate_id, :handler, :wish, :idempotency_key]
    defstruct @enforce_keys
  end

  defmodule ReadRequest do
    @enforce_keys [:aggregate_id, :handler]
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
        %Headwater.Aggregate.AggregateWorker{
          id: request.aggregate_id,
          handler: request.handler,
          registry: @registry,
          supervisor: @supervisor,
          event_store: @event_store
        }
        |> ensure_started()
        |> Headwater.Aggregate.AggregateWorker.propose_wish(request.wish, request.idempotency_key)
        |> Headwater.Aggregate.Result.new()
      end

      def read_state(request = %ReadRequest{}) do
        %Headwater.Aggregate.AggregateWorker{
          id: request.aggregate_id,
          handler: request.handler,
          registry: @registry,
          supervisor: @supervisor,
          event_store: @event_store
        }
        |> ensure_started()
        |> Headwater.Aggregate.AggregateWorker.current_state()
        |> Headwater.Aggregate.Result.new()
      end

      defp ensure_started(aggregate) do
        Headwater.Aggregate.AggregateWorker.new(aggregate)

        aggregate
      end
    end
  end
end

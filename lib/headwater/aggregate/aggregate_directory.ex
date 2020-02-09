defmodule Headwater.AggregateDirectory do
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
    @enforce_keys [:event_id, :state]
    defstruct @enforce_keys

    def new({:ok, {latest_event_id, state}}) do
      {:ok,
       %Result{
         event_id: latest_event_id,
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

  defmacro __using__(registry: registry, supervisor: supervisor, event_store: event_store) do
    quote do
      @registry unquote(registry)
      @supervisor unquote(supervisor)
      @event_store unquote(event_store)

      use Headwater.Aggregate.Expand, aggregate_directory: __MODULE__

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
        |> Headwater.AggregateDirectory.Result.new()
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
        |> Headwater.AggregateDirectory.Result.new()
      end

      defp ensure_started(aggregate) do
        Headwater.Aggregate.AggregateWorker.new(aggregate)

        aggregate
      end
    end
  end
end

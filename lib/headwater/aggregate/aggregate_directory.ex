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
    def new({:ok, %AggregateConfig{aggregate_number: 0, aggregate_state: nil}}) do
      {:warn, :empty_aggregate}
    end

    def new({:ok, %AggregateConfig{aggregate_state: aggregate_state}) do
      {:ok, aggregate_state}
    end

    def new({:error, :execute, response}) do
      response
    end

    def new({:error, :next_state, response}) do
      response
    end
  end

  defmacro __using__(opts) do
    registry = Keyword.get(opts, :registry)
    event_store = Keyword.get(opts, :event_store)
    supervisor = Keyword.get(opts, :supervisor)

    listeners = List.wrap(Keyword.get(opts, :listeners, []))

    quote do
      @registry unquote(registry)
      @supervisor unquote(supervisor)
      @event_store unquote(event_store)
      @listeners unquote(listeners)

      use Headwater.Aggregate.Expand, aggregate_directory: __MODULE__

      def handle(request = %WriteRequest{}) do
        %Headwater.Aggregate.AggregateConfig{
          id: request.aggregate_id,
          handler: request.handler,
          registry: @registry,
          supervisor: @supervisor,
          event_store: @event_store,
          aggregate_state: nil
        }
        |> ensure_started()
        |> Headwater.Aggregate.AggregateWorker.propose_wish(request)
        |> Headwater.AggregateDirectory.Result.new()
      end

      def read_state(request = %ReadRequest{}) do
        %Headwater.Aggregate.AggregateConfig{
          id: request.aggregate_id,
          handler: request.handler,
          registry: @registry,
          supervisor: @supervisor,
          event_store: @event_store,
          aggregate_state: nil
        }
        |> ensure_started()
        |> Headwater.Aggregate.AggregateWorker.current_state()
        |> Headwater.AggregateDirectory.Result.new()
      end

      defp ensure_started(aggregate_config) do
        Headwater.Aggregate.AggregateWorker.new(aggregate_config)

        aggregate
      end
    end
  end
end

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
    @derive {Jason.Encoder, only: [:state]}
    defstruct [:aggregate_id, :event_id, :state]

    def new({:ok, {latest_event_id = 0, state = nil}}, aggregate_id) do
      result = %Result{
        event_id: latest_event_id,
        state: state,
        aggregate_id: aggregate_id
      }

      {:warn, {:empty_aggregate, result}}
    end

    def new({:ok, {latest_event_id, state}}, aggregate_id) do
      {:ok,
       %Result{
         event_id: latest_event_id,
         state: state,
         aggregate_id: aggregate_id
       }}
    end

    def new({:error, :execute, response}, _aggregate_id) do
      response
    end

    def new({:error, :next_state, response}, _aggregate_id) do
      response
    end

    defimpl Jason.Encoder, for: [Headwater.AggregateDirectory.Result] do
      def encode(struct, opts) do
        Jason.Encode.map(Map.from_struct(struct.state), opts)
      end
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
        %Headwater.Aggregate.AggregateWorker{
          id: request.aggregate_id,
          handler: request.handler,
          registry: @registry,
          supervisor: @supervisor,
          event_store: @event_store
        }
        |> ensure_started()
        |> Headwater.Aggregate.AggregateWorker.propose_wish(request.wish, request.idempotency_key)
        |> Headwater.AggregateDirectory.Result.new(request.aggregate_id)
        |> notify_listeners()
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
        |> Headwater.AggregateDirectory.Result.new(request.aggregate_id)
      end

      defp ensure_started(aggregate) do
        Headwater.Aggregate.AggregateWorker.new(aggregate)

        aggregate
      end

      defp notify_listeners(result) do
        require Logger
        case result do
          {:ok, %Headwater.AggregateDirectory.Result{}} ->
            Logger.log(:info, "Notifying listeners #{inspect(result)}")
            Enum.each(@listeners, & &1.check_for_new_data())

          _ ->
            :ok
        end

        result
      end
    end
  end
end

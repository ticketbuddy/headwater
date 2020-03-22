defmodule Headwater.Aggregate.Directory do
  require Logger
  alias Headwater.Config
  alias Headwater.Aggregate.AggregateConfig
  alias Headwater.Aggregate.Directory.{Result, WriteRequest, ReadRequest}

  @callback handle(WriteRequest.t(), Config.t()) :: {:ok, Result.t()}
  @callback read_state(ReadRequest.t()) :: {:ok, Result.t()}

  require Logger

  def handle(request = %WriteRequest{}, config = %Config{}) do
    %Headwater.Aggregate.AggregateConfig{
      id: request.aggregate_id,
      handler: request.handler,
      registry: config.registry,
      supervisor: config.supervisor,
      event_store: config.event_store,
      aggregate_state: nil
    }
    |> ensure_started()
    |> Headwater.Aggregate.AggregateWorker.propose_wish(request)
    |> Result.new()
    |> notify_event_bus_listeners(config)
  end

  def handle(request = %ReadRequest{}, config = %Config{}) do
    %Headwater.Aggregate.AggregateConfig{
      id: request.aggregate_id,
      handler: request.handler,
      registry: config.registry,
      supervisor: config.supervisor,
      event_store: config.event_store,
      aggregate_state: nil
    }
    |> ensure_started()
    |> Headwater.Aggregate.AggregateWorker.current_state()
    |> Result.new()
  end

  defp ensure_started(aggregate_config) do
    Logger.info("Ensuring #{aggregate_config.id} started.")
    Headwater.Aggregate.AggregateWorker.new(aggregate_config)

    aggregate_config
  end

  def notify_event_bus_listeners(result, config = %Config{}) do
    case config.listener do
      nil ->
        result

      listener ->
        listener.broadcast_check_for_recorded_events()
        result
    end
  end
end

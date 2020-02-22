defmodule Headwater.Aggregate.IdempotencyTest do
  use ExUnit.Case
  alias Headwater.Aggregate.{Idempotency, AggregateConfig}

  setup do
    aggregate_config = %AggregateConfig{
      id: "agg-def",
      handler: nil,
      registry: nil,
      supervisor: nil,
      event_store: nil,
      aggregate_state: nil
    }

    %{
      aggregate_config: aggregate_config
    }
  end

  test "stores idempotency ID" do
    idempotency_key = "dont-run-me-twice"

    aggregate_config = %AggregateConfig{
      id: "agg-def",
      handler: nil,
      registry: nil,
      supervisor: nil,
      event_store: nil,
      aggregate_state: nil
    }

    assert {:ok, :idempotency_key_available} ==
             Idempotency.key_status(aggregate_config, idempotency_key)

    assert aggregate_config == Idempotency.store(aggregate_config, idempotency_key)

    assert {:error, :idempotency_key_used} ==
             Idempotency.key_status(aggregate_config, idempotency_key)
  end
end

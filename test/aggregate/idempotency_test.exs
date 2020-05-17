defmodule Headwater.Aggregate.IdempotencyTest do
  use ExUnit.Case
  alias Headwater.Aggregate.{Idempotency, AggregateConfig}

  setup do
    :ets.delete_all_objects(:headwater_idempotency)

    :ok
  end

  test "stores idempotency ID" do
    idempotency_key = "dont-run-me-twice"

    assert {:ok, :idempotency_key_available} ==
             Idempotency.key_status(idempotency_key)

    assert true == Idempotency.store(idempotency_key)

    assert {:error, :idempotency_key_used} ==
             Idempotency.key_status(idempotency_key)
  end
end

defmodule Headwater.Aggregate.Directory.Result do
  def new({:ok, nil}) do
    {:warn, :empty_aggregate}
  end

  def new({:ok, aggregate_state}) do
    {:ok, aggregate_state}
  end

  def new({:error, :execute, response}) do
    response
  end

  def new({:error, :next_state, response}) do
    response
  end
end

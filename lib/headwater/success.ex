defmodule Headwater.Success do
  def success?(results) when is_list(results) do
    Enum.all?(results, &success?/1)
  end

  def success?({:ok, :idempotent_request_succeeded}), do: true
  def success?({:ok, _event}), do: true
  def success?(:ok), do: true
  def success?({:error, _reason}), do: false
  def success?(:error), do: false
end

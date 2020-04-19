defmodule Headwater.Aggregate.Id do
  @moduledoc """
  Every ID is prefixed using the aggregate's id_prefix callback.
  This ensures that only one prefix is added.
  """

  @uuid_v4_hex_length 32

  @doc ~S"""
  Adds or modifies a prefix on a hexed uuid v4 ID (length: 32 chars).

  ## Examples

      iex> prefix_id("creditor_", "8790ce86756844c18e6ac51708524e7e")
      {:ok, "creditor_8790ce86756844c18e6ac51708524e7e"}

      iex> prefix_id("creditor_", "account_8790ce86756844c18e6ac51708524e7e")
      {:ok, "creditor_8790ce86756844c18e6ac51708524e7e"}

      iex> prefix_id("foo_", "a_8790ce86756844c18e6ac51708524e7e")
      {:ok, "foo_8790ce86756844c18e6ac51708524e7e"}

      iex> prefix_id("foo_", "invalid_prefix_8790ce86756844c18e6ac51708524e7e")
      {:warn, :invalid_id}
  """
  def prefix_id(prefix, id) do
    case is_valid?(id) do
      true -> {:ok, prefix <> String.slice(id, -@uuid_v4_hex_length, @uuid_v4_hex_length)}
      false -> {:warn, :invalid_id}
    end
  end

  @doc ~S"""
  Validates an id.

  ## Examples
      iex> is_valid?("8790ce86756844c18e6ac51708524e7e")
      true

      iex> is_valid?("creditor_8790ce86756844c18e6ac51708524e7e")
      true

      iex> is_valid?("pre_fix_8790ce86756844c18e6ac51708524e7e")
      false

      iex> is_valid?("creditor8790ce86756844c18e6ac51708524e7e")
      false
  """
  def is_valid?(id) do
    case String.length(id) do
      32 -> true
      num when num < 32 -> false
      _num -> prefix_ends_with_underscore?(id) && only_one_underscore?(id)
    end
  end

  defp prefix_ends_with_underscore?(id) do
    String.slice(id, -(@uuid_v4_hex_length + 1), 1) == "_"
  end

  defp only_one_underscore?(id) do
    1 == id |> String.graphemes() |> Enum.count(&(&1 == "_"))
  end
end

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

      iex> prefix_id("item_", "product_8790ce86756844c18e6ac51708524e7e")
      {:ok, "item_8790ce86756844c18e6ac51708524e7e"}

      iex> prefix_id("seat_", "item_8790ce86756844c18e6ac51708524e7e.34578")
      {:ok, "seat_8790ce86756844c18e6ac51708524e7e.34578"}

      iex> prefix_id("foo_", "a_8790ce86756844c18e6ac51708524e7e")
      {:ok, "foo_8790ce86756844c18e6ac51708524e7e"}

      iex> prefix_id("foo_", "invalid_prefix_8790ce86756844c18e6ac51708524e7e")
      {:warn, :invalid_id}
  """
  def prefix_id(prefix, id) do
    case is_valid?(id) do
      true ->
        {_old_prefix, id} = pop_prefix(id)
        {:ok, prefix <> id}

      false ->
        {:warn, :invalid_id}
    end
  end

  @doc ~S"""
  Validates an id.

  ## Examples
      iex> pop_prefix("8790ce86756844c18e6ac51708524e7e")
      {"", "8790ce86756844c18e6ac51708524e7e"}

      iex> pop_prefix("shop_8790ce86756844c18e6ac51708524e7e")
      {"shop_", "8790ce86756844c18e6ac51708524e7e"}

      iex> pop_prefix("item_8790ce86756844c18e6ac51708524e7e.73438h")
      {"item_", "8790ce86756844c18e6ac51708524e7e.73438h"}
  """
  def pop_prefix(id) do
    case String.split(id, "_") do
      [prefix, id] -> {prefix <> "_", id}
      [id] -> {"", id}
    end
  end

  @doc ~S"""
  Validates an id.

  ## Examples
      iex> is_valid?("8790ce86756844c18e6ac51708524e7e")
      true

      iex> is_valid?("creditor_8790ce86756844c18e6ac51708524e7e")
      true

      iex> is_valid?("item_8790ce86756844c18e6ac51708524e7e.484945j4j9j5")
      true

      iex> is_valid?("pre_fix_8790ce86756844c18e6ac51708524e7e")
      false

      iex> is_valid?("creditor8790ce86756844c18e6ac51708524e7e")
      false

      iex> is_valid?("areallyreallyreallyreallyreallylongprefix_5")
      false
  """
  def is_valid?(id) do
    case String.length(id) do
      @uuid_v4_hex_length -> true
      num when num < @uuid_v4_hex_length -> false
      _num -> exactly_one_underscore?(id) && id_at_least_v4_hex_length?(id)
    end
  end

  defp id_at_least_v4_hex_length?(id) do
    {prefix, id} = pop_prefix(id)
    String.length(id) >= @uuid_v4_hex_length
  end

  defp exactly_one_underscore?(id) do
    1 == id |> String.graphemes() |> Enum.count(&(&1 == "_"))
  end
end

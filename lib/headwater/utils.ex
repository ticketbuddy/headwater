defmodule Headwater.Utils do
  def to_module(snake_case_business_domain) do
    snake_case_business_domain
    |> String.split(".")
    |> Enum.map(&Macro.camelize/1)
    |> Enum.join(".")
    |> String.to_atom()
    |> List.wrap()
    |> Module.concat()
  end

  def atomize_keys(nil), do: nil

  def atomize_keys(struct = %{__struct__: _}) do
    struct
  end

  def atomize_keys(map = %{}) do
    map
    |> Enum.map(fn
      {k, v} when is_atom(k) -> {k, atomize_keys(v)}
      {k, v} -> {String.to_atom(k), atomize_keys(v)}
    end)
    |> Enum.into(%{})
  end

  def atomize_keys([head | rest]) do
    [atomize_keys(head) | atomize_keys(rest)]
  end

  def atomize_keys(not_a_map) do
    not_a_map
  end
end

defmodule Headwater.Aggregate.Expand do
  defmacro __using__(aggregate_directory: aggregate_directory) do
    quote do
      @aggregate_directory unquote(aggregate_directory)

      def expand(state, _mapping, _keys = []), do: state
      def expand(state, _mapping = []), do: state

      def expand(nil, _mapping, _keys), do: nil
      def expand(nil, _mapping), do: nil

      def expand(state, mapping) do
        expand(state, mapping, Keyword.keys(mapping))
      end

      def expand(state, mapping, [key | next_keys]) do
        {from_key, to_key, data_type} = get_key(key)
        handler = Keyword.get(mapping, from_key)

        ids_to_expand = Map.get(state, from_key)

        expanded = do_expansion(ids_to_expand, handler, mapping, next_keys)

        state =
          case data_type do
            :to_map -> Map.delete(state, :__struct__)
            :pass -> state
          end

        Map.put(state, to_key, expanded)
      end

      defp get_key({from_key, to_key}), do: {from_key, to_key, :to_map}
      defp get_key(key), do: {key, key, :pass}

      defp do_expansion(ids, handler, mapping, next_keys) when is_list(ids) do
        ids
        |> Enum.map(&do_expansion(&1, handler, mapping, next_keys))
        |> Enum.filter(&(!is_nil(&1)))
      end

      defp do_expansion(id, handler, mapping, next_keys) do
        output =
          case @aggregate_directory.read_state(%Headwater.AggregateDirectory.ReadRequest{
                 handler: handler,
                 aggregate_id: id
               }) do
            {:ok, output} -> output
            {:warn, {:empty_aggregate, result}} -> result
          end

        expand(output.state, mapping, next_keys)
      end
    end
  end
end

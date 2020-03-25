defmodule Headwater.Aggregate.Wish do
  defmacro defwish(name, attributes, to: aggregate_handler) do
    quote do
      defmodule unquote(name) do
        defstruct unquote(attributes)
        @attributes unquote(attributes)
        @aggregate_handler unquote(aggregate_handler)

        def aggregate_id(wish = %unquote(name){}) do
          Map.get(wish, by_id())
        end

        def aggregate_handler, do: @aggregate_handler

        defp by_id do
          case List.first(@attributes) do
            {key, _value} -> key
            key -> key
          end
        end
      end
    end
  end

  def new(wish_module, params) when is_binary(wish_module) do
    wish_module = Headwater.Utils.to_module(wish_module)

    new(wish_module, params)
  end

  def new(wish_module, params) when is_atom(wish_module) do
    # TODO atomize only used params for the wish to prevent memory leak.
    params = Headwater.Utils.atomize_keys(params)

    struct(wish_module, params)
  end

  def aggregate_id(wish) do
    module = wish.__struct__
    module.aggregate_id(wish)
  end

  def aggregate_handler(wish) do
    module = wish.__struct__
    module.aggregate_handler()
  end
end

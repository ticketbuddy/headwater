defmodule Headwater.Aggregate.Wish do
  defmacro __using__(_opts) do
    quote do
      import Headwater.Aggregate.Wish, only: [defwish: 3]

      @wishes []

      @before_compile Headwater.Aggregate.Wish
    end
  end

  defmacro defwish(name, attributes, to: aggregate_handler) do
    quote do
      @wishes [{unquote(name), unquote(attributes), unquote(aggregate_handler)} | @wishes]

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

  def aggregate_id(wish) do
    module = wish.__struct__
    module.aggregate_id(wish)
  end

  def aggregate_handler(wish) do
    module = wish.__struct__
    module.aggregate_handler()
  end

  defmacro __before_compile__(env) do
    quote do
      def wishes, do: @wishes
    end
  end
end

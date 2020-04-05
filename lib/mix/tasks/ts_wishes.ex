defmodule Mix.Tasks.TsWishes do
  use Mix.Task

  def run([router_module_arg]) do
    router_module = wish_router(router_module_arg)

    Mix.Task.run("compile")

    wishes = router_module.wishes()
    type_definitions = router_module.attributes() |> Map.new()

    wishes
    |> Enum.map(&to_typescript_definition(&1, type_definitions))
    |> Enum.join("")
    |> write_to_file()
  end

  defp wish_router(router_module_arg) do
    Module.concat([router_module_arg])
  end

  defp to_typescript_definition({wish_name, attributes, _handler}, type_definitions) do
    types = Map.get(type_definitions, wish_name, :no_types)

    case types do
      :no_types ->
        ""

      _type ->
        type = wish_name_to_type_name(wish_name)
        ~s(export type #{type} = {#{build_attributes(attributes, types)}
};\n\n)
    end
  end

  defp wish_name_to_type_name(wish_name), do: String.replace_prefix("#{wish_name}", "Elixir.", "")

  defp build_attributes(attributes, types) do
    attributes
    |> Enum.with_index()
    |> Enum.map(fn {attr, index} ->
      type = Enum.at(types, index, "any")

      case type do
        :hide -> ""
        _type -> "\n\t#{attr}: #{type};"
      end
    end)
    |> Enum.join("")
  end

  defp write_to_file(definition_string) do
    File.write("ts-definitions.ts", definition_string)
  end
end

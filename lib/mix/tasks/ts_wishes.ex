defmodule Mix.Tasks.TsWishes do
  use Mix.Task

  def run([router_module]) do
    Mix.Task.run("compile")

    wish_router(router_module).wishes()
    |> Enum.map(&to_typescript_definition/1)
    |> Enum.join("\n\n")
    |> write_to_file()
  end

  defp wish_router(router_module_arg) do
    Module.concat([router_module_arg])
  end

  defp to_typescript_definition({wish_name, attributes, _handler}) do
    type = wish_name_to_type_name(wish_name)
    ~s(export type #{type} = {
  #{build_attributes(attributes)}
};)
  end

  defp wish_name_to_type_name(wish_name), do: String.replace_prefix("#{wish_name}", "Elixir.", "")

  defp build_attributes(attributes) do
    attributes
    |> Enum.map(fn
      {:_string, attr} -> "#{attr}: string;"
      {:_number, attr} -> "#{attr}: number;"
      {:_date, attr} -> "#{attr}: string;"
      {:_map, attr} -> "#{attr}: map;"
      attribute -> "#{attribute}: any;"
    end)
    |> Enum.join("\n\t")
  end

  defp write_to_file(definition_string) do
    File.write("ts-definitions.ts", definition_string)
  end
end

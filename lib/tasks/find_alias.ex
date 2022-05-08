defmodule Mix.Tasks.FindAlias do
  use Mix.Task

  def run(args) do
    {[dir: directory], [module]} = OptionParser.parse!(args, strict: [dir: :string])
    module = Module.concat([module])

    get_files(directory)
    |> Enum.map(&search(&1, module))
    |> Enum.each(&pretty_print/1)
  end

  defp get_files(directory) do
    Path.wildcard("#{directory}/**/*.{ex, exs}")
  end

  defp search(file_path, module) do
    {_, alias_list} =
      get_ast(file_path)
      |> Macro.postwalk([], &traverse/2)

    alias_list
    |> List.flatten()
    |> Enum.filter(&(module == &1.name))
    |> Enum.map(&append_file_path(&1, file_path))
  end

  defp get_ast(file_path) do
    file_path
    |> Path.expand()
    |> File.read!()
    |> Code.string_to_quoted()
  end

  defp traverse(
         {:alias, _,
          [
            {{:., _, [{:__aliases__, _, module}, :{}]}, _, modules}
          ]} = node,
         acc
       ) do
    aliases_map =
      Enum.map(modules, &traverse_modules/1)
      |> Enum.map(&concat_module_name(&1, module))

    {node, [aliases_map | acc]}
  end

  defp traverse(node, acc), do: {node, acc}

  defp traverse_modules({:__aliases__, meta, module}) do
    %{name: module, line_number: Keyword.get(meta, :line)}
  end

  defp concat_module_name(module_map, module) do
    Map.update(module_map, :name, [], &Module.concat(module ++ &1))
  end

  defp append_file_path(module_map, file_path) do
    Map.put(module_map, :path, file_path)
  end

  defp pretty_print([]), do: ""

  defp pretty_print(module_map) do
    Enum.each(module_map, fn abc ->
      IO.puts("#{abc.path}:#{abc.line_number}")
    end)
  end
end

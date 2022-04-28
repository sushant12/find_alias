defmodule Mix.Tasks.FindAlias do
  use Mix.Task

  def run(args) do
    {[dir: directory], [module_alias]} = OptionParser.parse!(args, strict: [dir: :string])

    get_files(directory)
    |> Enum.map(fn file_path -> search(file_path, module_alias) end)
  end

  defp get_files(directory) do
    Path.wildcard("#{directory}/**/*.{ex, exs}")
  end

  defp search(file_path, module_alias) do
    ast =
      file_path
      |> Path.expand()
      |> File.read!()
      |> Code.string_to_quoted()

    {_ast, matches} = Macro.postwalk(ast, [], &traverse/2)
    matches
  end

  defp traverse(
         {
           :alias,
           _,
           [
             {
               {:., _, [{:__aliases__, meta, mod_name}, :{}]},
               _,
               al
             }
           ]
         } = node,
         acc
       ) do
    issue = %{
      line: meta[:line],
      aliases: Enum.map(al, &get_al/1) |> Enum.map(fn a -> Module.concat(mod_name ++ a) end)
    }

    {node, [issue | acc]}
  end

  defp traverse(node, acc), do: {node, acc}

  defp get_al({:__aliases__, _, alis}) do
    alis
  end
end

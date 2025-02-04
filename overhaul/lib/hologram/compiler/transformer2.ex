defmodule Hologram.Compiler.Transformer do
  alias Hologram.Compiler.Helpers

  # --- OPERATORS ---

  # Pipe operator, based on: https://ianrumford.github.io/elixir/pipe/clojure/thread-first/macro/2016/07/24/writing-your-own-elixir-pipe-operator.html
  def transform({:|>, _, _} = ast) do
    [{first_ast, _index} | rest_tuples] = Macro.unpipe(ast)

    rest_tuples
    |> Enum.reduce(first_ast, fn {rest_ast, rest_index}, this_ast ->
      Macro.pipe(this_ast, rest_ast, rest_index)
    end)
    |> transform()
  end
end

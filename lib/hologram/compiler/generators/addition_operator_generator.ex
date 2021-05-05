defmodule Hologram.Compiler.AdditionOperatorGenerator do
  alias Hologram.Compiler.Generator

  def generate(left, right, context) do
    left = Generator.generate(left, context)
    right = Generator.generate(right, context)

    "Kernel.$add(#{left}, #{right})"
  end
end

defmodule Hologram.Compiler.QuoteTransformerTest do
  use Hologram.TestCase, async: true

  alias Hologram.Compiler.{Context, QuoteTransformer}
  alias Hologram.Compiler.IR.{IntegerType, Quote}

  test "transform/2" do
    code = """
    quote do
      1
      2
    end
    """

    ast = ast(code)

    result = QuoteTransformer.transform(ast, %Context{})

    expected = %Quote{
      body: [
        %IntegerType{value: 1},
        %IntegerType{value: 2}
      ]
    }

    assert result == expected
  end
end

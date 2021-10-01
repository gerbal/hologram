defmodule Hologram.Compiler.EqualToOperatorEncoderTest do
  use Hologram.Test.UnitCase, async: true

  alias Hologram.Compiler.{Context, Encoder, Opts}
  alias Hologram.Compiler.IR.{EqualToOperator, IntegerType}

  test "encode/3" do
    ir = %EqualToOperator{
      left: %IntegerType{value: 1},
      right: %IntegerType{value: 2}
    }

    result = Encoder.encode(ir, %Context{}, %Opts{})

    expected =
      "Elixir_Kernel.$equal_to({ type: 'integer', value: 1 }, { type: 'integer', value: 2 })"

    assert result == expected
  end
end

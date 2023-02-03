defmodule Hologram.Compiler.DetransformerTest do
  use Hologram.Test.UnitCase, async: true

  alias Hologram.Compiler.Detransformer
  alias Hologram.Compiler.IR

  test "addition operator" do
    left = %IR.IntegerType{value: 1}
    right = %IR.IntegerType{value: 2}
    ir = %IR.AdditionOperator{left: left, right: right}

    result = Detransformer.detransform(ir)
    expected = {:+, [line: 0], [1, 2]}

    assert result == expected
  end

  test "integer type" do
    ir = %IR.IntegerType{value: 123}
    result = Detransformer.detransform(ir)
    assert result == 123
  end

  test "variable" do
    ir = %IR.Variable{name: :test}
    result = Detransformer.detransform(ir)
    assert result == {:test, [line: 0], nil}
  end
end

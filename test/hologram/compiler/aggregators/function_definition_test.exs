defmodule Hologram.Compiler.Aggregators.FunctionDefinitionTest do
  use Hologram.Test.UnitCase, async: true

  alias Hologram.Compiler.Aggregator
  alias Hologram.Compiler.IR.{FunctionDefinition, ModuleDefinition, ModuleType}
  alias Hologram.Test.Fixtures.{PlaceholderModule1, PlaceholderModule2}

  test "aggregate/2" do
    ir = %FunctionDefinition{
      body: [
        %ModuleType{module: PlaceholderModule1},
        %ModuleType{module: PlaceholderModule2}
      ]
    }

    result = Aggregator.aggregate(ir, %{})

    assert Map.keys(result) == [PlaceholderModule1, PlaceholderModule2]
    assert %ModuleDefinition{} = result[PlaceholderModule1]
    assert %ModuleDefinition{} = result[PlaceholderModule2]
  end
end

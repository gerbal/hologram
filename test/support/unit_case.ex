defmodule Hologram.Test.UnitCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      import Hologram.Compiler.Reflection, only: [ast: 1, ir: 1]
      import Hologram.Test.Helpers
      import Hologram.Utils, only: [uuid_hex_regex: 0, uuid_regex: 0]
    end
  end
end

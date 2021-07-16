defmodule Hologram.Test.Fixtures.Compiler.Processor.Module16 do
  use Hologram.Page
  alias Hologram.Test.Fixtures.Compiler.Processor.Module9, warn: false

  def template do
    ~H"""
    test_text
    <Module9></Module9>
    test_text
    """
  end
end

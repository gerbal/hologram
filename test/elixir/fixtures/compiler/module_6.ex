defmodule Hologram.Test.Fixtures.Compiler.Module6 do
  use Hologram.Layout

  @impl Layout
  def template do
    ~H"""
    Module6 template
    """
  end
end

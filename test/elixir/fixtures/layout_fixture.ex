defmodule Hologram.Test.Fixtures.LayoutFixture do
  use Hologram.Layout

  @impl Layout
  def template do
    ~H"<slot />"
  end
end

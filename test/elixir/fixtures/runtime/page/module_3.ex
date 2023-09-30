defmodule Hologram.Test.Fixtures.Runtime.Page.Module3 do
  use Hologram.Page

  route "/hologram-test-fixtures-runtime-page-module3"

  layout Hologram.Test.Fixtures.Runtime.Page.Module4, a: 1, b: 2

  @impl Page
  def template do
    ~H"""
    Module3 template
    """
  end
end

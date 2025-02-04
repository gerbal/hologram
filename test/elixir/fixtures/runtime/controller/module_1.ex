defmodule Hologram.Test.Fixtures.Runtime.Controller.Module1 do
  use Hologram.Page

  route "/hologram-test-fixtures-runtime-controller-module1/:aaa/ccc/:bbb"

  param :aaa
  param :bbb

  layout Hologram.Test.Fixtures.LayoutFixture

  @impl Page
  def template do
    ~H"""
    param_aaa = {@aaa}, param_bbb = {@bbb}
    """
  end
end

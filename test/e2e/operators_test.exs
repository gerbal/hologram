defmodule Hologram.Features.OperatorsTest do
  use Hologram.Test.E2ECase, async: false

  @moduletag :e2e

  feature "addition", %{session: session} do
    session
    |> visit("/e2e/operators/addition")
    |> click(css("#button"))
    |> assert_has(css("#text", text: "Result = 3"))
  end

  feature "boolean and", %{session: session} do
    session
    |> visit("/e2e/operators/boolean-and")
    |> click(css("#button"))
    |> assert_has(css("#text", text: "Result = true"))
  end

  feature "module attribute", %{session: session} do
    session
    |> visit("/e2e/operators/module-attribute")
    |> click(css("#button"))
    |> assert_has(css("#text", text: "Result = test_value"))
  end

  feature "multiplication", %{session: session} do
    session
    |> visit("/e2e/operators/multiplication")
    |> click(css("#button"))
    |> assert_has(css("#text", text: "Result = 6"))
  end

  feature "subtraction", %{session: session} do
    session
    |> visit("/e2e/operators/subtraction")
    |> click(css("#button"))
    |> assert_has(css("#text", text: "Result = 4"))
  end
end

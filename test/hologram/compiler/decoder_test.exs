defmodule Hologram.Compiler.DecoderTest do
  use Hologram.TestCase, async: true
  alias Hologram.Compiler.Decoder

  test "integer" do
    input = %{"type" => "integer", "value" => 1}
    assert Decoder.decode(input) == 1
  end

  test "string" do
    input = %{"type" => "string", "value" => "test"}
    assert Decoder.decode(input) == "test"
  end

  test "map" do
    input =
      %{
        "type" => "map",
        "data" => %{
          "~string[test_key]" => %{
            "type" => "string",
            "value" => "test_value"
          }
        }
      }

    result = Decoder.decode(input)
    expected = %{"test_key" => "test_value"}

    assert result == expected
  end
end

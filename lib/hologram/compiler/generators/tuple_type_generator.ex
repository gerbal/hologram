defmodule Hologram.Compiler.TupleTypeGenerator do
  use Hologram.Compiler.TypeEncoder
  alias Hologram.Compiler.{Context, Opts}

  def generate(data, %Context{} = context, %Opts{} = opts) do
    "{ type: 'tuple', data: #{encode_as_array(data, context, opts)} }"
  end
end

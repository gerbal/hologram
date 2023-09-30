defmodule Hologram.Commons.ETS do
  @doc """
  Creates a named, public ETS table.
  """
  @spec create_named_table(atom) :: :ets.tid()
  def create_named_table(table_name) do
    :ets.new(table_name, [:named_table, :public])
    :ets.whereis(table_name)
  end
end

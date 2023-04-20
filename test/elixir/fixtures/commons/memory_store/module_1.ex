# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Hologram.Test.Fixtures.Commons.MemoryStore.Module1 do
  use Hologram.Commons.MemoryStore

  @dump_path "#{File.cwd!()}/tmp/test_fixture_memory_store_1.bin"

  @impl MemoryStore
  def populate_table do
    populate_table_from_file(@dump_path)
    :ok
  end

  def dump_path, do: @dump_path
end

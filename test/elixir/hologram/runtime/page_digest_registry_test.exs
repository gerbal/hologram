defmodule Hologram.Runtime.PageDigestRegistryTest do
  use Hologram.Test.BasicCase, async: false

  import Hologram.Runtime.PageDigestRegistry
  import Hologram.Test.Stubs
  import Mox

  alias Hologram.Commons.ETS
  alias Hologram.Runtime.PageDigestRegistry

  use_module_stub :page_digest_registry

  setup :set_mox_global

  setup do
    stub_with(PageDigestRegistryMock, PageDigestRegistryStub)
    setup_page_digest_registry_dump(PageDigestRegistryStub)

    :ok
  end

  test "init/1" do
    assert init(nil) == {:ok, nil}

    ets_table_name = PageDigestRegistryStub.ets_table_name()

    assert ets_table_exists?(ets_table_name)

    assert ETS.get_all(ets_table_name) == %{
             module_a: :module_a_digest,
             module_b: :module_b_digest,
             module_c: :module_c_digest
           }
  end

  describe "lookup/2" do
    setup do
      init(nil)
      :ok
    end

    test "module entry exists" do
      assert lookup(:module_b) == :module_b_digest
    end

    test "module entry doesn't exist" do
      assert_raise KeyError, "key :module_d not found in the PLT", fn ->
        lookup(:module_d)
      end
    end
  end

  test "start_link/1" do
    assert {:ok, pid} = PageDigestRegistry.start_link([])
    assert is_pid(pid)
    assert ets_table_exists?(PageDigestRegistryStub.ets_table_name())
  end
end

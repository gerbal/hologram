defmodule Hologram.Commons.PLTTest do
  use Hologram.Test.BasicCase, async: true
  import Hologram.Commons.PLT

  alias Hologram.Commons.ETS
  alias Hologram.Commons.PLT
  alias Hologram.Commons.Reflection
  alias Hologram.Commons.SerializationUtils

  @tmp_path Reflection.tmp_path()
  @dump_dir_path "#{@tmp_path}/#{__MODULE__}"
  @dump_file_path "#{@dump_dir_path}/test.plt"

  @items [
    {:my_key_1, :my_value_1},
    {:my_key_2, :my_value_2}
  ]

  setup do
    clean_dir(@dump_dir_path)
    [plt: put(start(), @items)]
  end

  test "delete/2", %{plt: %{table_ref: table_ref} = plt} do
    assert delete(plt, :my_key_2) == plt
    assert ETS.get(table_ref, :my_key_2) == :error
  end

  describe "dump/2" do
    test "creates nested path dirs if they don't exist", %{plt: plt} do
      dump_dir_path = "#{@tmp_path}/nested_1/nested_2/nested_3"
      dump_file_path = "#{dump_dir_path}/test.plt"

      assert dump(plt, dump_file_path) == plt
      assert File.exists?(dump_dir_path)
    end

    test "writes serialized items to the given file", %{plt: plt} do
      assert dump(plt, @dump_file_path) == plt

      items =
        @dump_file_path
        |> File.read!()
        |> SerializationUtils.deserialize()

      assert items == Enum.into(@items, %{})
    end
  end

  describe "get/2" do
    test "resolve ETS table by reference", %{plt: plt} do
      assert get(plt, :my_key_2) == {:ok, :my_value_2}
    end

    test "resolve ETS table by name" do
      table_name = random_atom()

      [table_name: table_name]
      |> start()
      |> put(@items)

      plt = %PLT{table_name: table_name}
      assert get(plt, :my_key_2) == {:ok, :my_value_2}
    end
  end

  describe "get!/2" do
    test "key exists", %{plt: plt} do
      assert get!(plt, :my_key_2) == :my_value_2
    end

    test "key doesn't exist", %{plt: plt} do
      assert_raise KeyError, "key :my_key_3 not found in the PLT", fn ->
        get!(plt, :my_key_3)
      end
    end
  end

  test "get_all/1", %{plt: plt} do
    assert get_all(plt) == Enum.into(@items, %{})
  end

  describe "handle_call/3" do
    # Tested in start/1 tests:
    # test "get_table_ref"
  end

  # Tested in start/1 tests:
  # test "init/1"

  test "load/2", %{plt: plt} do
    dump(plt, @dump_file_path)

    plt_2 = start()

    assert load(plt_2, @dump_file_path) == plt_2
    assert get_all(plt_2) == Enum.into(@items, %{})
  end

  describe "maybe_load/2" do
    test "dump file exists" do
      data =
        @items
        |> Enum.into(%{})
        |> SerializationUtils.serialize()

      File.write!(@dump_file_path, data)

      plt = start()

      assert maybe_load(plt, @dump_file_path) == plt
      assert get_all(plt) == Enum.into(@items, %{})
    end

    test "dump file doesn't exist" do
      plt = start()

      assert maybe_load(plt, @dump_file_path) == plt
      assert get_all(plt) == %{}
    end
  end

  test "put/2", %{plt: %{table_ref: table_ref} = plt} do
    items = [
      {:my_key_3, :my_value_3},
      {:my_key_4, :my_value_4}
    ]

    assert put(plt, items) == plt

    assert ETS.get!(table_ref, :my_key_3) == :my_value_3
    assert ETS.get!(table_ref, :my_key_4) == :my_value_4
  end

  test "put/3", %{plt: %{table_ref: table_ref} = plt} do
    assert put(plt, :my_key_3, :my_value_3) == plt
    assert ETS.get!(table_ref, :my_key_3) == :my_value_3
  end

  describe "start/1" do
    test "unnamed table" do
      assert %PLT{pid: pid, table_ref: table_ref, table_name: nil} = start()

      assert is_pid(pid)
      assert is_reference(table_ref)

      assert ets_table_exists?(table_ref)
    end

    test "named table" do
      table_name = random_atom()

      assert %PLT{pid: pid, table_ref: table_ref, table_name: ^table_name} =
               start(table_name: table_name)

      assert is_pid(pid)
      assert is_reference(table_ref)

      assert ets_table_exists?(table_ref)
      assert ets_table_exists?(table_name)
      assert ets_table_name_registered?(table_name)
    end
  end
end

defmodule Hologram.ExJsConsistency.Erlang.ListsTest do
  @moduledoc """
  IMPORTANT!
  Each Elixir consistency test has a related JavaScript test in test/javascript/erlang/lists_test.mjs
  Always update both together.
  """

  use Hologram.Test.BasicCase, async: true

  describe "flatten/1" do
    test "works with empty list" do
      assert :lists.flatten([]) == []
    end

    test "works with non-nested list" do
      assert :lists.flatten([1, 2, 3]) == [1, 2, 3]
    end

    test "works with nested list" do
      assert :lists.flatten([1, [2, [3, 4, 5], 6], 7]) == [1, 2, 3, 4, 5, 6, 7]
    end

    test "raises FunctionClauseError if the argument is not a list" do
      assert_raise FunctionClauseError, "no function clause matching in :lists.flatten/1", fn ->
        :lists.flatten(:abc)
      end
    end
  end

  describe "foldl/3" do
    setup do
      [fun: fn value, acc -> acc + value end]
    end

    test "reduces empty list", %{fun: fun} do
      assert :lists.foldl(fun, 0, []) == 0
    end

    test "reduces non-empty list", %{fun: fun} do
      assert :lists.foldl(fun, 0, [1, 2, 3]) == 6
    end

    test "raises FunctionClauseError if the first argument is not an anonymous function" do
      assert_raise FunctionClauseError, "no function clause matching in :lists.foldl/3", fn ->
        :lists.foldl(:abc, 0, [])
      end
    end

    test "raises FunctionClauseError if the first argument is an anonymous function with arity different than 2" do
      assert_raise FunctionClauseError, "no function clause matching in :lists.foldl/3", fn ->
        :lists.foldl(fn x -> x end, 0, [])
      end
    end

    test "raises CaseClauseError if the third argument is not a list", %{fun: fun} do
      assert_raise CaseClauseError, "no case clause matching: :abc", fn ->
        :lists.foldl(fun, 0, :abc)
      end
    end
  end

  describe "keyfind/3" do
    test "returns the tuple that contains the given value at the given one-based index" do
      assert :lists.keyfind(7, 3, [{1, 2}, :abc, {5, 6, 7}]) == {5, 6, 7}
    end

    test "returns false if there is no tuple that fulfills the given conditions" do
      assert :lists.keyfind(7, 3, [:abc]) == false
    end

    test "raises ArgumentError if the second argument (index) is not an integer" do
      assert_raise ArgumentError,
                   "errors were found at the given arguments:\n\n  * 2nd argument: not an integer\n",
                   fn ->
                     :lists.keyfind(:abc, :xyz, [])
                   end
    end

    test "raises ArgumentError if the second argument (index) is smaller than 1" do
      assert_raise ArgumentError,
                   "errors were found at the given arguments:\n\n  * 2nd argument: out of range\n",
                   fn ->
                     :lists.keyfind(:abc, 0, [])
                   end
    end

    test "raises ArgumentError if the third argument (tuples) is not a list" do
      assert_raise ArgumentError,
                   "errors were found at the given arguments:\n\n  * 3rd argument: not a list\n",
                   fn ->
                     :lists.keyfind(:abc, 1, :xyz)
                   end
    end
  end

  describe "reverse/1" do
    test "returns a list with the elements in the argument in reverse order" do
      assert :lists.reverse([1, 2, 3]) == [3, 2, 1]
    end

    test "raises FunctionClauseError if the argument is not a list" do
      assert_raise FunctionClauseError, "no function clause matching in :lists.reverse/1", fn ->
        :lists.reverse(:abc)
      end
    end
  end
end

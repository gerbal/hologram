defmodule Hologram.Compiler.NormalizerTest do
  use Hologram.Test.BasicCase, async: true
  import Hologram.Compiler.Normalizer

  describe "alias (__aliases__)" do
    test "3rd tuple elem is a list of atoms" do
      ast = {:__aliases__, [line: 1], [:Aaa, :Bbb]}
      assert normalize(ast) == ast
    end

    test "3rd tuple elem is a module" do
      ast = {:__aliases__, [line: 1], [Aaa.Bbb]}
      assert normalize(ast) == {:__aliases__, [line: 1], [:Aaa, :Bbb]}
    end
  end

  describe "atom" do
    test "module" do
      assert normalize(Aaa.Bbb) == {:__aliases__, [alias: false], [:Aaa, :Bbb]}
    end

    test "non-module" do
      assert normalize(:abc) == :abc
    end
  end

  describe "-> clause" do
    test "single expression block" do
      ast = {:->, [line: 1], [[Aaa], Bbb]}

      assert normalize(ast) ==
               {:->, [line: 1],
                [
                  [{:__aliases__, [alias: false], [:Aaa]}],
                  {:__block__, [], [{:__aliases__, [alias: false], [:Bbb]}]}
                ]}
    end

    test "multiple expression block" do
      ast = {:->, [line: 1], [[Aaa], {:__block__, [], [Bbb, Ccc]}]}

      assert normalize(ast) ==
               {:->, [line: 1],
                [
                  [{:__aliases__, [alias: false], [:Aaa]}],
                  {:__block__, [],
                   [
                     {:__aliases__, [alias: false], [:Bbb]},
                     {:__aliases__, [alias: false], [:Ccc]}
                   ]}
                ]}
    end

    test "with guard" do
      ast = {:->, [line: 1], [[{:when, [line: 1], [Aaa, Bbb]}], Ccc]}

      assert normalize(ast) ==
               {:->, [line: 1],
                [
                  [
                    {:when, [line: 1],
                     [
                       {:__aliases__, [alias: false], [:Aaa]},
                       {:__aliases__, [alias: false], [:Bbb]}
                     ]}
                  ],
                  {:__block__, [], [{:__aliases__, [alias: false], [:Ccc]}]}
                ]}
    end
  end

  describe "<- clause" do
    test "without guard" do
      ast = {:<-, [line: 1], [Aaa, Bbb]}

      assert normalize(ast) ==
               {:<-, [line: 1],
                [
                  {:__aliases__, [alias: false], [:Aaa]},
                  {:__aliases__, [alias: false], [:Bbb]}
                ]}
    end

    test "with guard" do
      ast =
        {:<-, [line: 1],
         [
           {:when, [line: 1], [Aaa, Bbb]},
           Ccc
         ]}

      assert normalize(ast) ==
               {:<-, [line: 1],
                [
                  {:when, [line: 1],
                   [
                     {:__aliases__, [alias: false], [:Aaa]},
                     {:__aliases__, [alias: false], [:Bbb]}
                   ]},
                  {:__aliases__, [alias: false], [:Ccc]}
                ]}
    end
  end

  describe "case" do
    test "single clause" do
      ast = {:case, [line: 1], [Aaa, [do: [{:->, [line: 2], [[Bbb], Ccc]}]]]}

      assert normalize(ast) ==
               {:case, [line: 1],
                [
                  {:__aliases__, [alias: false], [:Aaa]},
                  [
                    do: [
                      {:->, [line: 2],
                       [
                         [{:__aliases__, [alias: false], [:Bbb]}],
                         {:__block__, [], [{:__aliases__, [alias: false], [:Ccc]}]}
                       ]}
                    ]
                  ]
                ]}
    end

    test "multiple clauses" do
      ast =
        {:case, [line: 1],
         [
           Aaa,
           [
             do: [
               {:->, [line: 2],
                [
                  [Bbb],
                  {:__block__, [], [Ccc, Ddd]}
                ]}
             ]
           ]
         ]}

      assert normalize(ast) ==
               {:case, [line: 1],
                [
                  {:__aliases__, [alias: false], [:Aaa]},
                  [
                    do: [
                      {:->, [line: 2],
                       [
                         [{:__aliases__, [alias: false], [:Bbb]}],
                         {:__block__, [],
                          [
                            {:__aliases__, [alias: false], [:Ccc]},
                            {:__aliases__, [alias: false], [:Ddd]}
                          ]}
                       ]}
                    ]
                  ]
                ]}
    end
  end

  describe "cond" do
    test "single clause" do
      ast = {:cond, [line: 1], [[do: [{:->, [line: 2], [[Aaa], Bbb]}]]]}

      assert normalize(ast) ==
               {:cond, [line: 1],
                [
                  [
                    do: [
                      {:->, [line: 2],
                       [
                         [{:__aliases__, [alias: false], [:Aaa]}],
                         {:__block__, [], [{:__aliases__, [alias: false], [:Bbb]}]}
                       ]}
                    ]
                  ]
                ]}
    end

    test "multiple clauses" do
      ast =
        {:cond, [line: 1],
         [
           [
             do: [
               {:->, [line: 2], [[Aaa], Bbb]},
               {:->, [line: 3], [[Ccc], Ddd]}
             ]
           ]
         ]}

      assert normalize(ast) ==
               {:cond, [line: 1],
                [
                  [
                    do: [
                      {:->, [line: 2],
                       [
                         [{:__aliases__, [alias: false], [:Aaa]}],
                         {:__block__, [], [{:__aliases__, [alias: false], [:Bbb]}]}
                       ]},
                      {:->, [line: 3],
                       [
                         [{:__aliases__, [alias: false], [:Ccc]}],
                         {:__block__, [], [{:__aliases__, [alias: false], [:Ddd]}]}
                       ]}
                    ]
                  ]
                ]}
    end
  end

  describe "do block" do
    test "single expression" do
      ast = [do: Aaa]
      assert normalize(ast) == [do: {:__block__, [], [{:__aliases__, [alias: false], [:Aaa]}]}]
    end

    test "multiple expressions" do
      ast = [do: {:__block__, [], [Aaa, Bbb]}]

      assert normalize(ast) == [
               do:
                 {:__block__, [],
                  [{:__aliases__, [alias: false], [:Aaa]}, {:__aliases__, [alias: false], [:Bbb]}]}
             ]
    end
  end

  test "unquote" do
    ast = {{:unquote, [], [:%]}, [line: 1], [Aaa, Bbb]}

    assert normalize(ast) ==
             {:%, [line: 1],
              [
                {:__aliases__, [alias: false], [:Aaa]},
                {:__aliases__, [alias: false], [:Bbb]}
              ]}
  end

  test "list" do
    ast = [Aaa, Bbb, Ccc]

    assert normalize(ast) == [
             {:__aliases__, [alias: false], [:Aaa]},
             {:__aliases__, [alias: false], [:Bbb]},
             {:__aliases__, [alias: false], [:Ccc]}
           ]
  end

  test "tuple" do
    ast = {Aaa, Bbb, Ccc}

    assert normalize(ast) == {
             {:__aliases__, [alias: false], [:Aaa]},
             {:__aliases__, [alias: false], [:Bbb]},
             {:__aliases__, [alias: false], [:Ccc]}
           }
  end
end

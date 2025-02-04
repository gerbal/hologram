defmodule Hologram.Template.RendererTest do
  use Hologram.Test.BasicCase, async: false

  import Hologram.Template.Renderer
  import Hologram.Test.Stubs
  import Mox

  alias Hologram.Commons.ETS
  alias Hologram.Component
  alias Hologram.Runtime.AssetPathRegistry
  alias Hologram.Test.Fixtures.Template.Renderer.Module1
  alias Hologram.Test.Fixtures.Template.Renderer.Module10
  alias Hologram.Test.Fixtures.Template.Renderer.Module13
  alias Hologram.Test.Fixtures.Template.Renderer.Module14
  alias Hologram.Test.Fixtures.Template.Renderer.Module16
  alias Hologram.Test.Fixtures.Template.Renderer.Module17
  alias Hologram.Test.Fixtures.Template.Renderer.Module18
  alias Hologram.Test.Fixtures.Template.Renderer.Module19
  alias Hologram.Test.Fixtures.Template.Renderer.Module2
  alias Hologram.Test.Fixtures.Template.Renderer.Module21
  alias Hologram.Test.Fixtures.Template.Renderer.Module24
  alias Hologram.Test.Fixtures.Template.Renderer.Module25
  alias Hologram.Test.Fixtures.Template.Renderer.Module27
  alias Hologram.Test.Fixtures.Template.Renderer.Module28
  alias Hologram.Test.Fixtures.Template.Renderer.Module29
  alias Hologram.Test.Fixtures.Template.Renderer.Module3
  alias Hologram.Test.Fixtures.Template.Renderer.Module31
  alias Hologram.Test.Fixtures.Template.Renderer.Module34
  alias Hologram.Test.Fixtures.Template.Renderer.Module37
  alias Hologram.Test.Fixtures.Template.Renderer.Module39
  alias Hologram.Test.Fixtures.Template.Renderer.Module4
  alias Hologram.Test.Fixtures.Template.Renderer.Module40
  alias Hologram.Test.Fixtures.Template.Renderer.Module43
  alias Hologram.Test.Fixtures.Template.Renderer.Module45
  alias Hologram.Test.Fixtures.Template.Renderer.Module46
  alias Hologram.Test.Fixtures.Template.Renderer.Module48
  alias Hologram.Test.Fixtures.Template.Renderer.Module5
  alias Hologram.Test.Fixtures.Template.Renderer.Module50
  alias Hologram.Test.Fixtures.Template.Renderer.Module6
  alias Hologram.Test.Fixtures.Template.Renderer.Module7
  alias Hologram.Test.Fixtures.Template.Renderer.Module8
  alias Hologram.Test.Fixtures.Template.Renderer.Module9

  use_module_stub :asset_path_registry
  use_module_stub :page_digest_registry

  setup :set_mox_global

  test "multiple nodes" do
    nodes = [
      {:text, "abc"},
      {:component, Module3, [{"id", [text: "component_3"]}], []},
      {:text, "xyz"},
      {:component, Module7, [{"id", [text: "component_7"]}], []}
    ]

    assert render_dom(nodes, %{}, []) ==
             {"abc<div>state_a = 1, state_b = 2</div>xyz<div>state_c = 3, state_d = 4</div>",
              %{
                "component_3" => %Component.Client{state: %{a: 1, b: 2}},
                "component_7" => %Component.Client{state: %{c: 3, d: 4}}
              }}
  end

  test "nil nodes" do
    nodes = [
      {:text, "abc"},
      nil,
      {:text, "xyz"},
      nil
    ]

    assert render_dom(nodes, %{}, []) == {"abcxyz", %{}}
  end

  describe "stateful component" do
    test "without props or state" do
      node = {:component, Module1, [{"id", [text: "my_component"]}], []}

      assert render_dom(node, %{}, []) ==
               {"<div>abc</div>", %{"my_component" => %Component.Client{state: %{}}}}
    end

    test "with props" do
      node =
        {:component, Module2,
         [
           {"id", [text: "my_component"]},
           {"a", [text: "ddd"]},
           {"b", [expression: {222}]},
           {"c", [text: "fff", expression: {333}, text: "hhh"]}
         ], []}

      assert render_dom(node, %{}, []) ==
               {"<div>prop_a = ddd, prop_b = 222, prop_c = fff333hhh</div>",
                %{"my_component" => %Component.Client{state: %{}}}}
    end

    test "with state / only client struct returned from init/3" do
      node = {:component, Module3, [{"id", [text: "my_component"]}], []}

      assert render_dom(node, %{}, []) ==
               {"<div>state_a = 1, state_b = 2</div>",
                %{"my_component" => %Component.Client{state: %{a: 1, b: 2}}}}
    end

    test "with props and state, give state priority over prop if there are name conflicts" do
      node =
        {:component, Module4,
         [
           {"id", [text: "my_component"]},
           {"b", [text: "prop_b"]},
           {"c", [text: "prop_c"]}
         ], []}

      assert render_dom(node, %{}, []) ==
               {"<div>var_a = state_a, var_b = state_b, var_c = prop_c</div>",
                %{"my_component" => %Component.Client{state: %{a: "state_a", b: "state_b"}}}}
    end

    test "with only server struct returned from init/3" do
      node =
        {:component, Module5,
         [
           {"id", [text: "my_component"]},
           {"a", [text: "aaa"]},
           {"b", [text: "bbb"]}
         ], []}

      assert render_dom(node, %{}, []) ==
               {"<div>prop_a = aaa, prop_b = bbb</div>",
                %{"my_component" => %Component.Client{state: %{}}}}
    end

    test "with client and server structs returned from init/3" do
      node = {:component, Module6, [{"id", [text: "my_component"]}], []}

      assert render_dom(node, %{}, []) ==
               {"<div>state_a = 1, state_b = 2</div>",
                %{"my_component" => %Component.Client{state: %{a: 1, b: 2}}}}
    end

    test "with missing 'id' property" do
      node = {:component, Module13, [], []}

      assert_raise Hologram.TemplateSyntaxError,
                   "Stateful component Elixir.Hologram.Test.Fixtures.Template.Renderer.Module13 is missing the 'id' property.",
                   fn ->
                     render_dom(node, %{}, [])
                   end
    end

    test "cast props" do
      node =
        {:component, Module16,
         [
           {"id", [text: "my_component"]},
           {"prop_1", [text: "value_1"]},
           {"prop_2", [expression: {2}]},
           {"prop_3", [text: "aaa", expression: {2}, text: "bbb"]},
           {"prop_4", [text: "value_4"]}
         ], []}

      assert render_dom(node, %{}, []) ==
               {"",
                %{
                  "my_component" => %Component.Client{
                    state: %{
                      id: "my_component",
                      prop_1: "value_1",
                      prop_2: 2,
                      prop_3: "aaa2bbb"
                    }
                  }
                }}
    end

    test "with unregistered var used" do
      node =
        {:component, Module18,
         [{"id", [text: "component_18"]}, {"a", [text: "111"]}, {"c", [text: "333"]}], []}

      assert_raise KeyError,
                   ~s(key :c not found in: %{id: "component_18", a: "111", b: 222}),
                   fn ->
                     render_dom(node, %{}, [])
                   end
    end
  end

  describe "stateless component" do
    test "without props" do
      node = {:component, Module1, [], []}
      assert render_dom(node, %{}, []) == {"<div>abc</div>", %{}}
    end

    test "with props" do
      node =
        {:component, Module2,
         [
           {"a", [text: "ddd"]},
           {"b", [expression: {222}]},
           {"c", [text: "fff", expression: {333}, text: "hhh"]}
         ], []}

      assert render_dom(node, %{}, []) ==
               {"<div>prop_a = ddd, prop_b = 222, prop_c = fff333hhh</div>", %{}}
    end

    test "with unregistered var used" do
      node = {:component, Module17, [{"a", [text: "111"]}, {"b", [text: "222"]}], []}

      assert_raise KeyError, "key :b not found in: %{a: \"111\"}", fn ->
        render_dom(node, %{}, [])
      end
    end
  end

  describe "element" do
    test "non-void element, without attributes or children" do
      node = {:element, "div", [], []}
      assert render_dom(node, %{}, []) == {"<div></div>", %{}}
    end

    test "non-void element, with attributes" do
      node =
        {:element, "div",
         [
           {"attr_1", [text: "aaa"]},
           {"attr_2", [expression: {123}]},
           {"attr_3", [text: "ccc", expression: {987}, text: "eee"]}
         ], []}

      assert render_dom(node, %{}, []) ==
               {~s(<div attr_1="aaa" attr_2="123" attr_3="ccc987eee"></div>), %{}}
    end

    test "non-void element, with children" do
      node = {:element, "div", [], [{:element, "span", [], [text: "abc"]}, {:text, "xyz"}]}

      assert render_dom(node, %{}, []) == {"<div><span>abc</span>xyz</div>", %{}}
    end

    test "void element, without attributes" do
      node = {:element, "img", [], []}
      assert render_dom(node, %{}, []) == {"<img />", %{}}
    end

    test "void element, with attributes" do
      node =
        {:element, "img",
         [
           {"attr_1", [text: "aaa"]},
           {"attr_2", [expression: {123}]},
           {"attr_3", [text: "ccc", expression: {987}, text: "eee"]}
         ], []}

      assert render_dom(node, %{}, []) ==
               {~s(<img attr_1="aaa" attr_2="123" attr_3="ccc987eee" />), %{}}
    end

    test "boolean attributes" do
      node = {:element, "img", [{"attr_1", []}, {"attr_2", []}], []}

      assert render_dom(node, %{}, []) == {~s(<img attr_1 attr_2 />), %{}}
    end

    test "with nested stateful components" do
      node =
        {:element, "div", [{"attr", [text: "value"]}],
         [
           {:component, Module3, [{"id", [text: "component_3"]}], []},
           {:component, Module7, [{"id", [text: "component_7"]}], []}
         ]}

      assert render_dom(node, %{}, []) ==
               {~s(<div attr="value"><div>state_a = 1, state_b = 2</div><div>state_c = 3, state_d = 4</div></div>),
                %{
                  "component_3" => %Component.Client{
                    state: %{a: 1, b: 2}
                  },
                  "component_7" => %Component.Client{
                    state: %{c: 3, d: 4}
                  }
                }}
    end
  end

  test "expression" do
    node = {:expression, {123}}
    assert render_dom(node, %{}, []) == {"123", %{}}
  end

  test "text" do
    node = {:text, "abc"}
    assert render_dom(node, %{}, []) == {"abc", %{}}
  end

  describe "default slot" do
    test "with single node" do
      node = {:component, Module8, [], [text: "123"]}
      assert render_dom(node, %{}, []) == {"abc123xyz", %{}}
    end

    test "with multiple nodes" do
      node = {:component, Module8, [], [text: "123", expression: {456}]}
      assert render_dom(node, %{}, []) == {"abc123456xyz", %{}}
    end

    test "nested components with slots, no slot tag in the top component template, not using vars" do
      node = {:component, Module8, [], [{:component, Module9, [], [text: "789"]}]}
      assert render_dom(node, %{}, []) == {"abcdef789uvwxyz", %{}}
    end

    test "nested components with slots, no slot tag in the top component template, using vars" do
      node = {:component, Module10, [{"id", [text: "component_10"]}], []}

      assert render_dom(node, %{}, []) ==
               {"10,11,10,12,10",
                %{
                  "component_10" => %Component.Client{state: %{a: 10}},
                  "component_11" => %Component.Client{state: %{a: 11}},
                  "component_12" => %Component.Client{state: %{a: 12}}
                }}
    end

    test "nested components with slots, slot tag in the top component template, not using vars" do
      node = {:component, Module31, [], [text: "abc"]}

      assert render_dom(node, %{}, []) == {"31a,32a,31b,33a,31c,abc,31x,33z,31y,32z,31z", %{}}
    end

    test "nested components with slots, slot tag in the top component template, using vars" do
      node =
        {:component, Module34, [{"id", [text: "component_34"]}, {"a", [text: "34a_prop"]}],
         [text: "abc"]}

      assert render_dom(node, %{}, []) ==
               {"34a_prop,35a_prop,34b_state,36a_prop,34c_state,abc,34x_state,36z_state,34y_state,35z_state,34z_state",
                %{
                  "component_34" => %Component.Client{
                    state: %{
                      id: "component_34",
                      c: "34c_state",
                      a: "34a_prop",
                      y: "34y_state",
                      x: "34x_state",
                      z: "34z_state",
                      b: "34b_state"
                    }
                  },
                  "component_35" => %Component.Client{
                    state: %{id: "component_35", a: "35a_prop", z: "35z_state"}
                  },
                  "component_36" => %Component.Client{
                    state: %{id: "component_36", a: "36a_prop", z: "36z_state"}
                  }
                }}
    end
  end

  describe "context" do
    setup do
      stub_with(AssetPathRegistryMock, AssetPathRegistryStub)
      stub_with(PageDigestRegistryMock, PageDigestRegistryStub)

      setup_asset_fixtures(AssetPathRegistryStub.static_dir_path())
      AssetPathRegistry.start_link([])

      setup_page_digest_registry(PageDigestRegistryStub)

      :ok
    end

    test "set in page, accessed in component nested in page" do
      ETS.put(PageDigestRegistryStub.ets_table_name(), Module39, :dummy_module_39_digest)

      assert render_page(Module39, []) ==
               {"prop_aaa = 123",
                %{
                  "layout" => %Component.Client{
                    context: %{}
                  },
                  "page" => %Component.Client{
                    context: %{
                      {Hologram.Runtime, :page_digest} => :dummy_module_39_digest,
                      {Hologram.Runtime, :page_mounted?} => true,
                      {:my_scope, :my_key} => 123
                    }
                  }
                }}
    end

    test "set in page, accessed in component nested in layout" do
      ETS.put(PageDigestRegistryStub.ets_table_name(), Module46, :dummy_module_46_digest)

      assert render_page(Module46, []) ==
               {"prop_aaa = 123",
                %{
                  "layout" => %Component.Client{
                    context: %{}
                  },
                  "page" => %Component.Client{
                    context: %{
                      {Hologram.Runtime, :page_digest} => :dummy_module_46_digest,
                      {Hologram.Runtime, :page_mounted?} => true,
                      {:my_scope, :my_key} => 123
                    }
                  }
                }}
    end

    test "set in page, accessed in layout" do
      ETS.put(PageDigestRegistryStub.ets_table_name(), Module40, :dummy_module_40_digest)

      assert render_page(Module40, []) ==
               {"prop_aaa = 123",
                %{
                  "layout" => %Component.Client{
                    context: %{}
                  },
                  "page" => %Component.Client{
                    context: %{
                      {Hologram.Runtime, :page_digest} => :dummy_module_40_digest,
                      {Hologram.Runtime, :page_mounted?} => true,
                      {:my_scope, :my_key} => 123
                    }
                  }
                }}
    end

    test "set in layout, accessed in component nested in page" do
      ETS.put(PageDigestRegistryStub.ets_table_name(), Module43, :dummy_module_43_digest)

      assert render_page(Module43, []) ==
               {"prop_aaa = 123",
                %{
                  "layout" => %Component.Client{
                    context: %{{:my_scope, :my_key} => 123}
                  },
                  "page" => %Component.Client{
                    context: %{
                      {Hologram.Runtime, :page_digest} => :dummy_module_43_digest,
                      {Hologram.Runtime, :page_mounted?} => true
                    }
                  }
                }}
    end

    test "set in layout, accessed in component nested in layout" do
      ETS.put(PageDigestRegistryStub.ets_table_name(), Module45, :dummy_module_45_digest)

      assert render_page(Module45, []) ==
               {"prop_aaa = 123",
                %{
                  "layout" => %Component.Client{
                    context: %{{:my_scope, :my_key} => 123}
                  },
                  "page" => %Component.Client{
                    context: %{
                      {Hologram.Runtime, :page_digest} => :dummy_module_45_digest,
                      {Hologram.Runtime, :page_mounted?} => true
                    }
                  }
                }}
    end

    test "set in component, accessed in component" do
      node = {:component, Module37, [{"id", [text: "component_37"]}], []}

      assert render_dom(node, %{}, []) ==
               {"prop_aaa = 123",
                %{
                  "component_37" => %Component.Client{
                    context: %{
                      {:my_scope, :my_key} => 123
                    }
                  }
                }}
    end
  end

  describe "render_page" do
    setup do
      stub_with(AssetPathRegistryMock, AssetPathRegistryStub)
      stub_with(PageDigestRegistryMock, PageDigestRegistryStub)

      setup_asset_fixtures(AssetPathRegistryStub.static_dir_path())
      AssetPathRegistry.start_link([])

      setup_page_digest_registry(PageDigestRegistryStub)

      :ok
    end

    test "inside layout slot" do
      ETS.put(PageDigestRegistryStub.ets_table_name(), Module14, :dummy_module_14_digest)

      assert render_page(Module14, []) ==
               {"layout template start, page template, layout template end",
                %{
                  "layout" => %Component.Client{},
                  "page" => %Component.Client{
                    context: %{
                      {Hologram.Runtime, :page_digest} => :dummy_module_14_digest,
                      {Hologram.Runtime, :page_mounted?} => true
                    }
                  }
                }}
    end

    test "cast page params" do
      ETS.put(PageDigestRegistryStub.ets_table_name(), Module19, :dummy_module_19_digest)

      params_dom =
        [
          {"param_1", [text: "value_1"]},
          {"param_2", [text: "value_2"]},
          {"param_3", [text: "value_3"]}
        ]

      assert render_page(Module19, params_dom) ==
               {"",
                %{
                  "layout" => %Component.Client{},
                  "page" => %Component.Client{
                    context: %{
                      {Hologram.Runtime, :page_digest} => :dummy_module_19_digest,
                      {Hologram.Runtime, :page_mounted?} => true
                    },
                    state: %{param_1: "value_1", param_3: "value_3"}
                  }
                }}
    end

    test "cast layout explicit static props" do
      ETS.put(PageDigestRegistryStub.ets_table_name(), Module25, :dummy_module_25_digest)

      assert render_page(Module25, []) ==
               {"",
                %{
                  "layout" => %Component.Client{
                    state: %{id: "layout", prop_1: "prop_value_1", prop_3: "prop_value_3"}
                  },
                  "page" => %Component.Client{
                    context: %{
                      {Hologram.Runtime, :page_digest} => :dummy_module_25_digest,
                      {Hologram.Runtime, :page_mounted?} => true
                    }
                  }
                }}
    end

    test "cast layout props passed implicitely from page state" do
      ETS.put(PageDigestRegistryStub.ets_table_name(), Module27, :dummy_module_27_digest)

      assert render_page(Module27, []) ==
               {"",
                %{
                  "layout" => %Component.Client{
                    state: %{id: "layout", prop_1: "prop_value_1", prop_3: "prop_value_3"}
                  },
                  "page" => %Component.Client{
                    context: %{
                      {Hologram.Runtime, :page_digest} => :dummy_module_27_digest,
                      {Hologram.Runtime, :page_mounted?} => true
                    },
                    state: %{
                      prop_1: "prop_value_1",
                      prop_2: "prop_value_2",
                      prop_3: "prop_value_3"
                    }
                  }
                }}
    end

    test "aggregate page vars, giving state priority over param when there are name conflicts" do
      ETS.put(PageDigestRegistryStub.ets_table_name(), Module21, :dummy_module_21_digest)

      params_dom =
        [
          {"key_1", [text: "param_value_1"]},
          {"key_2", [text: "param_value_2"]}
        ]

      assert render_page(Module21, params_dom) ==
               {"key_1 = param_value_1, key_2 = state_value_2, key_3 = state_value_3",
                %{
                  "layout" => %Component.Client{},
                  "page" => %Component.Client{
                    context: %{
                      {Hologram.Runtime, :page_digest} => :dummy_module_21_digest,
                      {Hologram.Runtime, :page_mounted?} => true
                    },
                    state: %{key_2: "state_value_2", key_3: "state_value_3"}
                  }
                }}
    end

    test "aggregate layout vars, giving state priority over prop when there are name conflicts" do
      ETS.put(PageDigestRegistryStub.ets_table_name(), Module24, :dummy_module_24_digest)

      assert render_page(Module24, []) ==
               {"key_1 = prop_value_1, key_2 = state_value_2, key_3 = state_value_3",
                %{
                  "layout" => %Component.Client{
                    state: %{key_2: "state_value_2", key_3: "state_value_3"}
                  },
                  "page" => %Component.Client{
                    context: %{
                      {Hologram.Runtime, :page_digest} => :dummy_module_24_digest,
                      {Hologram.Runtime, :page_mounted?} => true
                    }
                  }
                }}
    end

    test "merge the page component client struct into the result" do
      ETS.put(PageDigestRegistryStub.ets_table_name(), Module28, :dummy_module_28_digest)

      assert render_page(Module28, []) ==
               {"",
                %{
                  "layout" => %Component.Client{},
                  "page" => %Component.Client{
                    context: %{
                      {Hologram.Runtime, :page_digest} => :dummy_module_28_digest,
                      {Hologram.Runtime, :page_mounted?} => true
                    },
                    state: %{state_1: "value_1", state_2: "value_2"}
                  }
                }}
    end

    test "merge the layout component client struct into the result" do
      ETS.put(PageDigestRegistryStub.ets_table_name(), Module29, :dummy_module_29_digest)

      assert render_page(Module29, []) ==
               {"",
                %{
                  "layout" => %Hologram.Component.Client{
                    state: %{state_1: "value_1", state_2: "value_2"}
                  },
                  "page" => %Hologram.Component.Client{
                    context: %{
                      {Hologram.Runtime, :page_digest} => :dummy_module_29_digest,
                      {Hologram.Runtime, :page_mounted?} => true
                    }
                  }
                }}
    end

    test "inject runtime clients data" do
      ETS.put(
        PageDigestRegistryStub.ets_table_name(),
        Module48,
        "102790adb6c3b1956db310be523a7693"
      )

      assert {html,
              %{
                "layout" => %Component.Client{
                  context: %{}
                },
                "page" => %Component.Client{
                  context: %{
                    {Hologram.Runtime, :page_digest} => "102790adb6c3b1956db310be523a7693",
                    {Hologram.Runtime, :page_mounted?} => true
                  }
                }
              }} = render_page(Module48, [])

      expected =
        ~s/clientsData: Type.map([[Type.bitstring("layout"), Type.map([[Type.atom("__struct__"), Type.atom("Elixir.Hologram.Component.Client")], [Type.atom("context"), Type.map([])], [Type.atom("next_command"), Type.atom("nil")], [Type.atom("state"), Type.map([])]])], [Type.bitstring("page"), Type.map([[Type.atom("__struct__"), Type.atom("Elixir.Hologram.Component.Client")], [Type.atom("context"), Type.map([[Type.tuple([Type.atom("Elixir.Hologram.Runtime"), Type.atom("page_digest")]), Type.bitstring("102790adb6c3b1956db310be523a7693")], [Type.tuple([Type.atom("Elixir.Hologram.Runtime"), Type.atom("page_mounted?")]), Type.atom("true")]])], [Type.atom("next_command"), Type.atom("nil")], [Type.atom("state"), Type.map([])]])]])/

      assert String.contains?(html, expected)
    end

    test "inject runtime page module" do
      ETS.put(
        PageDigestRegistryStub.ets_table_name(),
        Module48,
        "102790adb6c3b1956db310be523a7693"
      )

      assert {html,
              %{
                "layout" => %Component.Client{
                  context: %{}
                },
                "page" => %Component.Client{
                  context: %{
                    {Hologram.Runtime, :page_digest} => "102790adb6c3b1956db310be523a7693",
                    {Hologram.Runtime, :page_mounted?} => true
                  }
                }
              }} = render_page(Module48, [])

      expected =
        ~s/pageModule: Type.atom("Elixir.Hologram.Test.Fixtures.Template.Renderer.Module48")/

      assert String.contains?(html, expected)
    end

    test "inject runtime page params" do
      ETS.put(
        PageDigestRegistryStub.ets_table_name(),
        Module50,
        "102790adb6c3b1956db310be523a7693"
      )

      params_dom =
        [
          {"key_1", [expression: {123}]},
          {"key_2", [text: "value_2"]}
        ]

      assert {html,
              %{
                "layout" => %Component.Client{
                  context: %{}
                },
                "page" => %Component.Client{
                  context: %{
                    {Hologram.Runtime, :page_digest} => "102790adb6c3b1956db310be523a7693",
                    {Hologram.Runtime, :page_mounted?} => true
                  }
                }
              }} = render_page(Module50, params_dom)

      expected =
        ~s/pageParams: Type.map([[Type.atom("key_1"), Type.integer(123n)], [Type.atom("key_2"), Type.bitstring("value_2")]])/

      assert String.contains?(html, expected)
    end
  end
end

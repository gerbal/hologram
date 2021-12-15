# DEFER: refactor & test

defmodule Mix.Tasks.Compile.Hologram do
  use Mix.Task.Compiler
  require Logger

  alias Hologram.{MixProject, Utils}
  alias Hologram.Compiler.{Builder, CallGraph, CallGraphBuilder, ModuleDefAggregator, ModuleDefStore, Reflection}
  alias Hologram.Template.Builder, as: TemplateBuilder

  @root_path Reflection.root_path()

  def run(opts \\ []) do
    Logger.debug("Hologram compiler started")

    output_path = resolve_output_path()

    File.mkdir_p!(output_path)
    remove_old_files(output_path)

    runtime_build_task = build_runtime()

    ModuleDefStore.create()
    CallGraph.create()

    templatables = Reflection.list_templatables(opts)
    templates = TemplateBuilder.build_all(templatables)
    dump_template_store(templates)

    pages = Reflection.list_pages(opts)
    dump_page_list(pages)

    module_defs = aggregate_module_defs(pages)
    call_graph = build_call_graph(pages, module_defs, templates)

    digests = build_pages(pages, output_path, module_defs, call_graph)
    build_manifest(digests, output_path)
    copy_router()

    Task.await(runtime_build_task, :infinity)

    CallGraph.destroy()
    ModuleDefStore.destroy()

    Logger.debug("Hologram compiler finished")

    :ok
  end

  defp aggregate_module_defs(pages) do
    pages
    |> Utils.map_async(&ModuleDefAggregator.aggregate/1)
    |> Utils.await_tasks()

    ModuleDefStore.get_all()
  end

  defp build_call_graph(pages, module_defs, templates) do
    pages
    |> Utils.map_async(&CallGraphBuilder.build(&1, module_defs, templates, nil))
    |> Utils.await_tasks()

    CallGraph.get()
  end

  defp build_manifest(digests, output_path) do
    json =
      Enum.into(digests, %{})
      |> Jason.encode!()

    "#{output_path}/manifest.json"
    |> File.write!(json)
  end

  defp build_page(page, output_path, module_defs, call_graph) do
    js = Builder.build(page, module_defs, call_graph)
    output = "\"use strict\";\n\n" <> js

    digest =
      :crypto.hash(:md5, output)
      |> Base.encode16()
      |> String.downcase()

    "#{output_path}/page-#{digest}.js"
    |> File.write!(output)

    {page, digest}
  end

  defp build_pages(pages, output_path, module_defs, call_graph) do
    pages
    |> Utils.map_async(&build_page(&1, output_path, module_defs, call_graph))
    |> Utils.await_tasks()
  end

  defp build_runtime do
    Task.async(fn ->
      assets_path = Reflection.assets_path()
      System.cmd("npm", ["install"], cd: assets_path)
      Mix.Task.run("esbuild", ["hologram", "--log-level=warning"])
    end)
  end

  defp copy_router do
    source_path =
      Reflection.router_module()
      |> Reflection.source_path()

    target_path = Reflection.root_priv_path() <> "/router.ex"

    File.cp!(source_path, target_path)
  end

  defp dump_page_list(pages) do
    Reflection.root_priv_path()
    |> File.mkdir_p!()

    data = Utils.serialize(pages)

    Reflection.root_page_list_path()
    |> File.write!(data)
  end

  defp dump_template_store(templates) do
    build_path = Reflection.build_path()
    File.mkdir_p!(build_path)

    data = Utils.serialize(templates)

    Reflection.template_store_dump_path()
    |> File.write!(data)
  end

  defp remove_old_files(output_path) do
    "#{output_path}/*"
    |> Path.wildcard()
    |> Enum.each(&File.rm!/1)
  end

  defp resolve_output_path do
    if MixProject.is_dep?() do
      "#{@root_path}/../../priv/static/hologram"
    else
      "#{@root_path}/priv/static/hologram"
    end
  end
end

# credo:disable-for-this-file Credo.Check.Refactor.ABCSize
defmodule Mix.Tasks.Compile.Hologram do
  @moduledoc """
  Builds Hologram runtime and page JavaScript files for the current project.
  """

  use Mix.Task.Compiler

  alias Hologram.Commons.PLT
  alias Hologram.Commons.Reflection
  alias Hologram.Compiler
  alias Hologram.Compiler.CallGraph

  require Logger

  @impl Mix.Task.Compiler
  def run(_args) do
    root_path = Reflection.root_path()
    build_dir = Reflection.build_dir()
    assets_source_dir = "#{root_path}/deps/hologram/assets"

    opts = [
      assets_source_dir: assets_source_dir,
      build_dir: build_dir,
      bundle_dir: "#{root_path}/priv/static/hologram",
      esbuild_path: "#{root_path}/deps/hologram/assets/node_modules/.bin/esbuild",
      js_formatter_bin_path: "#{root_path}/deps/hologram/assets/node_modules/.bin/prettier",
      js_formatter_config_path: "#{root_path}/deps/hologram/assets/.prettierrc.json",
      js_source_dir: "#{assets_source_dir}/js",
      tmp_dir: "#{build_dir}/tmp"
    ]

    compile(opts)
  end

  @doc """
  Builds Hologram project JavaScript bundles, call graph of the code,
  PLTs needed by the runtime and PLTs needed to speed up future compilation.
  """
  @spec compile(keyword) :: :ok
  def compile(opts) do
    Logger.info("Hologram: compiler started")

    {new_module_digest_plt, old_module_digest_plt, module_digest_plt_dump_path} =
      build_module_digest_plts(opts)

    diff = Compiler.diff_module_digest_plts(old_module_digest_plt, new_module_digest_plt)

    {ir_plt, ir_plt_dump_path} = build_ir_plt(opts, diff)

    {call_graph, call_graph_dump_path} = build_call_graph(opts, ir_plt, diff)

    Compiler.install_js_deps(opts[:assets_source_dir])

    bundle_runtime(call_graph, ir_plt, opts)

    page_digest_plt = PLT.start()

    page_digest_plt_dump_path =
      Path.join([opts[:build_dir], Reflection.page_digest_plt_dump_file_name()])

    call_graph
    |> bundle_pages(ir_plt, opts)
    |> Enum.each(fn {module, digest} -> PLT.put(page_digest_plt, module, digest) end)

    PLT.dump(page_digest_plt, page_digest_plt_dump_path)
    CallGraph.dump(call_graph, call_graph_dump_path)
    PLT.dump(ir_plt, ir_plt_dump_path)
    PLT.dump(new_module_digest_plt, module_digest_plt_dump_path)

    Logger.info("Hologram: compiler finished")

    :ok
  end

  defp build_call_graph(opts, ir_plt, diff) do
    call_graph = CallGraph.start()
    call_graph_dump_path = opts[:build_dir] <> "/call_graph.bin"
    CallGraph.maybe_load(call_graph, call_graph_dump_path)
    CallGraph.patch(call_graph, ir_plt, diff)

    {call_graph, call_graph_dump_path}
  end

  defp build_ir_plt(opts, diff) do
    ir_plt = PLT.start()
    ir_plt_dump_path = opts[:build_dir] <> "/ir.plt"
    PLT.maybe_load(ir_plt, ir_plt_dump_path)
    Compiler.patch_ir_plt(ir_plt, diff)

    {ir_plt, ir_plt_dump_path}
  end

  defp build_module_digest_plts(opts) do
    new_module_digest_plt = Compiler.build_module_digest_plt()
    old_module_digest_plt = PLT.start()
    module_digest_plt_dump_path = opts[:build_dir] <> "/module_digest.plt"
    PLT.maybe_load(old_module_digest_plt, module_digest_plt_dump_path)

    {new_module_digest_plt, old_module_digest_plt, module_digest_plt_dump_path}
  end

  defp bundle_pages(call_graph, ir_plt, opts) do
    Enum.map(Reflection.list_pages(), fn page_module ->
      if !function_exported?(page_module, :__route__, 0) do
        raise Hologram.CompileError,
          message:
            "Page '#{page_module}' doesn't have a route specified (use the route/1 macro to fix the issue)."
      end

      if !function_exported?(page_module, :__layout_module__, 0) do
        raise Hologram.CompileError,
          message:
            "Page '#{page_module}' doesn't have a layout module specified (use the layout/1 macro to fix the issue)."
      end

      page_bundle_opts = [
        esbuild_path: opts[:esbuild_path],
        js_formatter_bin_path: opts[:js_formatter_bin_path],
        js_formatter_config_path: opts[:js_formatter_config_path],
        entry_name: to_string(page_module),
        bundle_name: "page",
        tmp_dir: opts[:tmp_dir],
        bundle_dir: opts[:bundle_dir]
      ]

      {digest, _bundle_file, _source_map_file} =
        page_module
        |> Compiler.build_page_js(call_graph, ir_plt, opts[:js_source_dir])
        |> Compiler.bundle(page_bundle_opts)

      {page_module, digest}
    end)
  end

  defp bundle_runtime(call_graph, ir_plt, opts) do
    runtime_bundle_opts = [
      esbuild_path: opts[:esbuild_path],
      js_formatter_bin_path: opts[:js_formatter_bin_path],
      js_formatter_config_path: opts[:js_formatter_config_path],
      entry_name: "runtime",
      bundle_name: "runtime",
      tmp_dir: opts[:tmp_dir],
      bundle_dir: opts[:bundle_dir]
    ]

    opts[:js_source_dir]
    |> Compiler.build_runtime_js(call_graph, ir_plt)
    |> Compiler.bundle(runtime_bundle_opts)
  end
end

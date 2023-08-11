defmodule Hologram.Compiler.Builder do
  alias Hologram.Commons.CryptographicUtils
  alias Hologram.Commons.PLT
  alias Hologram.Compiler.CallGraph
  alias Hologram.Compiler.Context
  alias Hologram.Compiler.Encoder
  alias Hologram.Compiler.IR
  alias Hologram.Compiler.Reflection

  @doc """
  Extracts JavaScript source code for the given ported Erlang function and generates interpreter function definition statetement.
  """
  @spec build_erlang_function_definition(module, atom, integer, String.t()) :: String.t()
  def build_erlang_function_definition(module, function, arity, erlang_source_dir) do
    class = Encoder.encode_as_class_name(module)

    file_path =
      if module == :erlang do
        "#{erlang_source_dir}/erlang.mjs"
      else
        "#{erlang_source_dir}/#{module}.mjs"
      end

    source_code =
      if File.exists?(file_path) do
        extract_erlang_function_source_code(file_path, function, arity)
      else
        nil
      end

    if source_code do
      ~s/Interpreter.defineErlangFunction("#{class}", "#{function}", #{arity}, #{source_code});/
    else
      ~s/Interpreter.defineNotImplementedErlangFunction("#{module}", "#{function}", #{arity});/
    end
  end

  @doc """
  Builds a persistent lookup table (PLT) containing the BEAM defs digests for all the modules in the project.

  ## Examples

      iex> build_module_digest_plt(:abc)
      %PLT{pid: #PID<0.251.0>, name: :plt_abc}
  """
  @spec build_module_digest_plt(atom) :: PLT.t()
  def build_module_digest_plt(name) do
    plt = PLT.start(name: name)

    Reflection.list_loaded_otp_apps()
    |> Kernel.--([:hex])
    |> Reflection.list_elixir_modules()
    |> Task.async_stream(&rebuild_module_digest_plt_entry(plt, &1))
    |> Stream.run()

    plt
  end

  @doc """
  Builds JavaScript code for the given Hologram page.
  """
  @spec build_page_js(module, CallGraph.t(), PLT.t(), String.t()) :: String.t()
  # sobelow_skip ["DOS.BinToAtom"]
  def build_page_js(page, call_graph, ir_plt, source_dir) do
    # credo:disable-for-next-line Credo.Check.Warning.UnsafeToAtom
    clone_name = :"call_graph_#{__MODULE__}_#{page}"

    mfas = list_page_mfas(call_graph, page, clone_name)
    erlang_source_dir = source_dir <> "/erlang"

    """
    window.__hologramPageReachableFunctionDefs__ = (interpreterClass, typeClass) => {
      const Interpreter = interpreterClass;
      const Type = typeClass;

    #{render_erlang_function_defs(mfas, erlang_source_dir)}

    #{render_elixir_function_defs(mfas, ir_plt)}

    }\
    """
  end

  @doc """
  Builds Hologram runtime JavaScript source code.
  """
  @spec build_runtime_js(String.t(), CallGraph.t(), PLT.t()) :: String.t()
  def build_runtime_js(source_dir, call_graph, ir_plt) do
    mfas = list_runtime_mfas(call_graph)

    """
    "use strict";

    import Hologram from "#{source_dir}/hologram.mjs"
    import Interpreter from "#{source_dir}/interpreter.mjs"
    import Type from "#{source_dir}/interpreter.mjs"

    #{render_erlang_function_defs(mfas, "#{source_dir}/erlang")}

    #{render_elixir_function_defs(mfas, ir_plt)}\
    """
  end

  @doc """
  Builds Hologram runtime JS file and its source map.
  The generated filenames contain the hex digest of the built JS content.

  ## Examples

      iex> build_runtime_js_file("assets/node_modules/esbuild", "assets/js/hologram.mjs", "tmp")
      {"c4206fe5fa846da67e50ed03874ccbae",
       "tmp/hologram.runtime-c4206fe5fa846da67e50ed03874ccbae.js",
      "tmp/hologram.runtime-c4206fe5fa846da67e50ed03874ccbae.js.map"}
  """
  @spec build_runtime_js_file(String.t(), String.t(), String.t()) ::
          {String.t(), String.t(), String.t()}
  # sobelow_skip ["CI.System"]
  def build_runtime_js_file(esbuild_path, source_file, output_dir) do
    output_file = output_dir <> "/hologram.runtime.js"

    cmd = [
      source_file,
      "--bundle",
      "--minify",
      "--outfile=#{output_file}",
      "--sourcemap",
      "--target=es2020"
    ]

    System.cmd(esbuild_path, cmd, env: [])

    digest =
      output_file
      |> File.read!()
      |> CryptographicUtils.digest(:md5, :hex)

    output_file_with_digest = output_dir <> "/hologram.runtime-#{digest}.js"

    source_map_file = output_file <> ".map"
    source_map_file_with_digest = output_file_with_digest <> ".map"

    File.rename!(output_file, output_file_with_digest)
    File.rename!(source_map_file, source_map_file_with_digest)

    js_with_replaced_source_map_url =
      output_file_with_digest
      |> File.read!()
      |> String.replace(
        "//# sourceMappingURL=hologram.runtime.js.map",
        "//# sourceMappingURL=hologram.runtime-#{digest}.js.map"
      )

    File.write!(output_file_with_digest, js_with_replaced_source_map_url)

    {digest, output_file_with_digest, source_map_file_with_digest}
  end

  @doc """
  Compares two module digest PLTs and returns the added, removed, and updated modules lists.

  ## Examples

      iex> old_plt = %PLT{pid: #PID<0.251.0>, name: :my_old_plt}
      iex> new_plt = %PLT{pid: #PID<0.259.0>, name: :my_new_plt}
      iex> diff_module_digest_plts(old_plt, new_plt)
      %{
        added_modules: [Module5, Module9],
        removed_modules: [Module1, Module3],
        updated_modules: [Module6, Module2]
      }
  """
  @spec diff_module_digest_plts(PLT.t(), PLT.t()) :: %{
          added_modules: list,
          removed_modules: list,
          updated_modules: list
        }
  def diff_module_digest_plts(old_plt, new_plt) do
    old_mapset = mapset_from_plt(old_plt)
    new_mapset = mapset_from_plt(new_plt)

    removed_modules =
      old_mapset
      |> MapSet.difference(new_mapset)
      |> MapSet.to_list()

    added_modules =
      new_mapset
      |> MapSet.difference(old_mapset)
      |> MapSet.to_list()

    updated_modules =
      old_mapset
      |> MapSet.intersection(new_mapset)
      |> MapSet.to_list()
      |> Enum.filter(&(PLT.get(old_plt, &1) != PLT.get(new_plt, &1)))

    %{
      added_modules: added_modules,
      removed_modules: removed_modules,
      updated_modules: updated_modules
    }
  end

  @doc """
  Returns the list of MFAs ({module, function, arity} tuples) that are reachable by the given page.
  MFAs required by the runtime are excluded.
  """
  @spec list_page_mfas(CallGraph.t(), module, atom) :: list(mfa)
  def list_page_mfas(call_graph, entry_page, clone_name) do
    call_graph_clone = CallGraph.clone(call_graph, name: clone_name)
    layout_module = entry_page.__hologram_layout_module__()
    runtime_mfas = list_runtime_mfas(call_graph)

    call_graph_clone
    |> CallGraph.add_edge(entry_page, {entry_page, :__hologram_layout_module__, 0})
    |> CallGraph.add_edge(entry_page, {entry_page, :__hologram_layout_props__, 0})
    |> CallGraph.add_edge(entry_page, {entry_page, :action, 3})
    |> CallGraph.add_edge(entry_page, {entry_page, :template, 0})
    |> CallGraph.add_edge(entry_page, {layout_module, :action, 3})
    |> CallGraph.add_edge(entry_page, {layout_module, :template, 0})
    |> CallGraph.reachable(entry_page)
    |> Enum.filter(&is_tuple/1)
    |> Kernel.--(runtime_mfas)
  end

  @doc """
  Groups the given MFAs ({module, function, arity} tuples) by module.
  """
  @spec group_mfas_by_module(list(mfa)) :: %{module => mfa}
  def group_mfas_by_module(mfas) do
    Enum.group_by(mfas, fn {module, _function, _arity} -> module end)
  end

  @doc """
  Lists MFAs ({module, function, arity} tuples) required by the runtime JS script.
  """
  @spec list_runtime_mfas(CallGraph.t()) :: list(mfa)
  def list_runtime_mfas(call_graph) do
    # These Elixir functions are used directly by the JS runtime:
    entry_mfas = [
      # Interpreter.comprehension()
      {Enum, :into, 2},

      # Interpreter.comprehension()
      {Enum, :to_list, 1},

      # Hologram.inspect()
      {Kernel, :inspect, 2},

      # Hologram.raiseError()
      {:erlang, :error, 1},

      # Interpreter.#matchConsPattern()
      {:erlang, :hd, 1},

      # Interpreter.#matchConsPattern()
      {:erlang, :tl, 1},

      # Interpreter.dotOperator()
      {:maps, :get, 2}
    ]

    # Add call graph edges for Erlang functions depending on other Erlang functions.
    CallGraph.add_edge(call_graph, {:erlang, :"/=", 2}, {:erlang, :==, 2})
    CallGraph.add_edge(call_graph, {:erlang, :error, 1}, {:erlang, :error, 2})

    call_graph
    |> CallGraph.reachable_mfas(entry_mfas)
    |> Enum.uniq()
    |> Enum.sort()
  end

  @doc """
  Given a diff of changes, updates the IR persistent lookup table (PLT)
  by deleting entries for modules that have been removed,
  rebuilding the IR of modules that have been updated,
  and adding the IR of new modules.

  ## Examples

      iex> plt = %PLT{pid: #PID<0.251.0>, name: :plt_abc}
      iex> diff = %{
      ...>   added_modules: [Module1, Module2],
      ...>   removed_modules: [Module5, Module6],
      ...>   updated_modules: [Module3, Module4]
      ...> }
      iex> patch_ir_plt(plt, diff)
      %PLT{pid: #PID<0.251.0>, name: :plt_abc}
  """
  @spec patch_ir_plt(PLT.t(), map) :: PLT.t()
  def patch_ir_plt(ir_plt, diff) do
    diff.removed_modules
    |> Task.async_stream(&PLT.delete(ir_plt, &1))
    |> Stream.run()

    (diff.updated_modules ++ diff.added_modules)
    |> Task.async_stream(&rebuild_ir_plt_entry(ir_plt, &1))
    |> Stream.run()

    ir_plt
  end

  @doc """
  Keeps in the body of module definition IR only those expressions that are function definitions of reachable functions.
  """
  @spec prune_module_def(IR.ModuleDefinition.t(), list(mfa)) :: IR.ModuleDefinition.t()
  def prune_module_def(module_def_ir, reachable_mfas) do
    module = module_def_ir.module.value

    module_reachable_mfas =
      reachable_mfas
      |> Enum.filter(fn {reachable_module, _function, _arity} -> reachable_module == module end)
      |> MapSet.new()

    function_defs =
      Enum.filter(module_def_ir.body.expressions, fn
        %IR.FunctionDefinition{name: function, arity: arity} ->
          MapSet.member?(module_reachable_mfas, {module, function, arity})

        _fallback ->
          false
      end)

    %IR.ModuleDefinition{
      module: module_def_ir.module,
      body: %IR.Block{expressions: function_defs}
    }
  end

  defp extract_erlang_function_source_code(file_path, function, arity) do
    key = "#{function}/#{arity}"
    start_marker = "// start #{key}"
    end_marker = "// end #{key}"

    regex =
      ~r/#{Regex.escape(start_marker)}[[:space:]]+"#{Regex.escape(key)}":[[:space:]]+(.+),[[:space:]]+#{Regex.escape(end_marker)}/s

    file_contents = File.read!(file_path)

    case Regex.run(regex, file_contents) do
      [_full_capture, source_code] -> source_code
      nil -> nil
    end
  end

  defp filter_elixir_mfas(mfas) do
    Enum.filter(mfas, fn {module, _function, _arity} -> Reflection.alias?(module) end)
  end

  defp filter_erlang_mfas(mfas) do
    Enum.filter(mfas, fn {module, _function, _arity} -> !Reflection.alias?(module) end)
  end

  defp mapset_from_plt(plt) do
    plt
    |> PLT.get_all()
    |> Map.keys()
    |> MapSet.new()
  end

  defp rebuild_ir_plt_entry(plt, module) do
    PLT.put(plt, module, IR.for_module(module))
  end

  defp rebuild_module_digest_plt_entry(plt, module) do
    data =
      module
      |> Reflection.module_beam_defs()
      |> :erlang.term_to_binary(compressed: 0)

    digest = CryptographicUtils.digest(data, :sha256, :binary)
    PLT.put(plt.name, module, digest)
  end

  defp render_elixir_function_defs(mfas, ir_plt) do
    mfas
    |> filter_elixir_mfas()
    |> group_mfas_by_module()
    |> Enum.sort()
    |> Enum.map_join("\n\n", fn {module, module_mfas} ->
      ir_plt
      |> PLT.get!(module)
      |> prune_module_def(module_mfas)
      |> Encoder.encode(%Context{module: module})
    end)
  end

  defp render_erlang_function_defs(mfas, erlang_source_dir) do
    mfas
    |> filter_erlang_mfas()
    |> Enum.map_join("\n\n", fn {module, function, arity} ->
      build_erlang_function_definition(module, function, arity, erlang_source_dir)
    end)
  end
end

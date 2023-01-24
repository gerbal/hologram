defmodule Hologram.Compiler.Expander do
  alias Hologram.Compiler.Context
  alias Hologram.Compiler.Evaluator
  alias Hologram.Compiler.Helpers
  alias Hologram.Compiler.IR
  alias Hologram.Compiler.IR.Alias
  alias Hologram.Compiler.IR.AliasDirective
  alias Hologram.Compiler.IR.Block
  alias Hologram.Compiler.IR.IgnoredExpression
  alias Hologram.Compiler.IR.ImportDirective
  alias Hologram.Compiler.IR.ModuleAttributeDefinition
  alias Hologram.Compiler.IR.ModuleAttributeOperator
  alias Hologram.Compiler.IR.ModuleType
  alias Hologram.Compiler.Reflection
  alias Hologram.Compiler.Transformer

  def expand(ir, context)

  def expand(%IR.AdditionOperator{left: left, right: right}, %Context{} = context) do
    left = expand(left, context)
    right = expand(right, context)

    {%IR.AdditionOperator{left: left, right: right}, context}
  end

  def expand(%Alias{segments: segments}, %Context{aliases: defined_aliases} = context) do
    expanded_alias_segs = expand_alias_segs(segments, defined_aliases)
    module = Helpers.module(expanded_alias_segs)

    {%ModuleType{module: module, segments: expanded_alias_segs}, context}
  end

  def expand(
        %AliasDirective{alias_segs: alias_segs, as: as},
        %Context{aliases: defined_aliases} = context
      ) do
    expanded_alias_segs = expand_alias_segs(alias_segs, defined_aliases)
    new_defined_aliases = Map.put(defined_aliases, as, expanded_alias_segs)
    new_context = %{context | aliases: new_defined_aliases}

    {%IgnoredExpression{}, new_context}
  end

  def expand(%Block{expressions: exprs}, %Context{} = context) do
    {expanded_exprs, _new_context} =
      Enum.reduce(exprs, {[], context}, fn expr, {expanded_exprs, new_context} ->
        {expanded_expr, new_context} = expand(expr, new_context)
        {expanded_exprs ++ [expanded_expr], new_context}
      end)

    {%Block{expressions: expanded_exprs}, context}
  end

  def expand(
        %ImportDirective{alias_segs: alias_segs, only: only, except: except},
        %Context{aliases: defined_aliases} = context
      ) do
    expanded_alias_segs = expand_alias_segs(alias_segs, defined_aliases)
    module = Helpers.module(expanded_alias_segs)

    functions = filter_exports(:functions, Reflection.functions(module), only, except)
    macros = filter_exports(:macros, Reflection.macros(module), only, except)

    new_context =
      context
      |> Context.put_functions(module, functions)
      |> Context.put_macros(module, macros)

    {%IgnoredExpression{}, new_context}
  end

  def expand(
        %ModuleAttributeDefinition{name: name, expression: expr},
        %Context{} = context
      ) do
    {expanded_ir, _context} = expand(expr, context)

    value =
      expanded_ir
      |> Evaluator.evaluate()
      |> Macro.escape()
      |> Transformer.transform(context)

    new_context = Context.put_module_attribute(context, name, value)

    {%IgnoredExpression{}, new_context}
  end

  def expand(
        %ModuleAttributeOperator{name: name},
        %Context{module_attributes: module_attributes} = context
      ) do
    {module_attributes[name], context}
  end

  def expand(ir, %Context{} = context) do
    {ir, context}
  end

  defp expand_alias_segs([head | tail] = alias_segs, defined_aliases) do
    if defined_aliases[head] do
      defined_aliases[head] ++ tail
    else
      alias_segs
    end
  end

  defp filter_exports(type, exports, only, except)

  defp filter_exports(:functions, exports, :functions, []) do
    exports
  end

  defp filter_exports(:functions, exports, :functions, except) do
    Enum.reject(exports, &(&1 in except))
  end

  defp filter_exports(:functions, _exports, :macros, _except) do
    []
  end

  defp filter_exports(:macros, exports, :macros, []) do
    exports
  end

  defp filter_exports(:macros, exports, :macros, except) do
    Enum.reject(exports, &(&1 in except))
  end

  defp filter_exports(:macros, _exports, :functions, _except) do
    []
  end

  defp filter_exports(_type, exports, :sigils, []) do
    Enum.filter(exports, fn {name, arity} ->
      to_string(name) =~ ~r/^sigil_[a-zA-Z]$/ && arity == 2
    end)
  end

  defp filter_exports(_type, exports, :sigils, except) do
    Enum.filter(exports, fn {name, arity} = export ->
      to_string(name) =~ ~r/^sigil_[a-zA-Z]$/ && arity == 2 && export not in except
    end)
  end

  defp filter_exports(_type, exports, [], []) do
    exports
  end

  defp filter_exports(_type, exports, only, []) do
    Enum.filter(exports, &(&1 in only))
  end

  defp filter_exports(_type, exports, [], except) do
    Enum.reject(exports, &(&1 in except))
  end
end

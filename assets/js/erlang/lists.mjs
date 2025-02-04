"use strict";

import Interpreter from "../interpreter.mjs";
import Type from "../type.mjs";

// IMPORTANT!
// If the given ported Erlang function calls other Erlang functions, then list such dependencies in a "deps" comment (see :erlang./=/2 for an example).
// Also, in such case add respective call graph edges in Hologram.Compiler.list_runtime_mfas/1.

const Erlang_Lists = {
  // start flatten/1
  "flatten/1": (list) => {
    if (!Type.isList(list)) {
      Interpreter.raiseFunctionClauseError(
        "no function clause matching in :lists.flatten/1",
      );
    }

    const data = list.data.reduce((acc, elem) => {
      if (Type.isList(elem)) {
        elem = Erlang_Lists["flatten/1"](elem);
        return acc.concat(elem.data);
      } else {
        return acc.concat(elem);
      }
    }, []);

    return Type.list(data);
  },
  // end flatten/1
  // deps: []

  // start foldl/3
  "foldl/3": (fun, initialAcc, list) => {
    if (!Type.isAnonymousFunction(fun) || fun.arity !== 2) {
      Interpreter.raiseFunctionClauseError(
        "no function clause matching in :lists.foldl/3",
      );
    }

    if (!Type.isList(list)) {
      Interpreter.raiseCaseClauseError(list);
    }

    return list.data.reduce(
      (acc, value) => Interpreter.callAnonymousFunction(fun, [value, acc]),
      initialAcc,
    );
  },
  // end foldl/3
  // deps: []

  // start keyfind/3
  "keyfind/3": (value, index, tuples) => {
    if (!Type.isInteger(index)) {
      Interpreter.raiseArgumentError(
        "errors were found at the given arguments:\n\n  * 2nd argument: not an integer\n",
      );
    }

    if (index.value < 1) {
      Interpreter.raiseArgumentError(
        "errors were found at the given arguments:\n\n  * 2nd argument: out of range\n",
      );
    }

    if (!Type.isList(tuples)) {
      Interpreter.raiseArgumentError(
        "errors were found at the given arguments:\n\n  * 3rd argument: not a list\n",
      );
    }

    for (const tuple of tuples.data) {
      if (Type.isTuple(tuple)) {
        if (
          tuple.data.length >= index.value &&
          Interpreter.isEqual(tuple.data[Number(index.value) - 1], value)
        ) {
          return tuple;
        }
      }
    }

    return Type.boolean(false);
  },
  // end keyfind/3
  // deps: []

  // start reverse/1
  "reverse/1": (list) => {
    if (!Type.isList(list)) {
      Interpreter.raiseFunctionClauseError(
        "no function clause matching in :lists.reverse/1",
      );
    }

    return Type.list(list.data.toReversed());
  },
  // end reverse/1
  // deps: []
};

export default Erlang_Lists;

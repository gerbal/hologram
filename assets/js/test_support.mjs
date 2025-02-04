"use strict";

import {assert} from "chai";
import Erlang from "./erlang/erlang.mjs";
import Erlang_Lists from "./erlang/lists.mjs";
import Erlang_Maps from "./erlang/maps.mjs";
import Erlang_Persistent_Term from "./erlang/persistent_term.mjs";
import Erlang_Unicode from "./erlang/unicode.mjs";
import HologramBoxedError from "./errors/boxed_error.mjs";
import HologramMatchError from "./errors/match_error.mjs";
import Interpreter from "./interpreter.mjs";
import sinonESM from "../node_modules/sinon/pkg/sinon-esm.js";
import Type from "./type.mjs";

function buildElixirKernelInspectFunction() {
  return (term) => {
    switch (term.type) {
      // TODO: handle correctly atoms which need to be double quoted, e.g. :"1"
      case "atom":
        if (Type.isBoolean(term) || Type.isNil(term)) {
          return term.value;
        }
        return ":" + term.value;

      // TODO: case "bitstring"

      case "float":
        if (Number.isInteger(term.value)) {
          return term.value.toString() + ".0";
        } else {
          return term.value.toString();
        }

      case "integer":
        return term.value.toString();

      case "list":
        if (term.isProper) {
          return (
            "[" +
            term.data
              .map((item) => Elixir_Kernel["inspect/1"](item))
              .join(", ") +
            "]"
          );
        } else {
          return (
            "[" +
            term.data
              .slice(0, -1)
              .map((item) => Elixir_Kernel["inspect/1"](item))
              .join(", ") +
            " | " +
            Elixir_Kernel["inspect/1"](term.data.slice(-1)[0]) +
            "]"
          );
        }

      case "string":
        return '"' + term.value.toString() + '"';

      case "tuple":
        return (
          "{" +
          term.data.map((item) => Elixir_Kernel["inspect/1"](item)).join(", ") +
          "}"
        );

      default:
        return Interpreter.serialize(term);
    }
  };
}

// This version of Elixir_Kernel is for tests only.
// The actual Elixir_Kernel is transpiled automatically during project build.
function buildElixirKernelModule() {
  return {
    "inspect/1": buildElixirKernelInspectFunction(),
  };
}

const Elixir_Kernel = buildElixirKernelModule();

export {assert} from "chai";
export const sinon = sinonESM;

export function assertBoxedError(callable, errorAliasStr, message) {
  const errorStruct = Type.errorStruct(errorAliasStr, message);

  let isErrorThrown = false;
  let isAnyAssertFailed = false;

  try {
    callable();
  } catch (error) {
    isErrorThrown = true;

    if (!(error instanceof HologramBoxedError)) {
      isAnyAssertFailed = true;
    } else if (!Interpreter.isStrictlyEqual(error.struct, errorStruct)) {
      isAnyAssertFailed = true;
    }
  }

  if (!isErrorThrown || isAnyAssertFailed) {
    assert.fail(`expected ${errorAliasStr}: ${message}`);
  }
}

export function assertBoxedFalse(boxed) {
  assert.isTrue(Type.isFalse(boxed));
}

export function assertBoxedTrue(boxed) {
  assert.isTrue(Type.isTrue(boxed));
}

export function assertMatchError(callable, value) {
  let isErrorThrown = false;
  let isAnyAssertFailed = false;

  try {
    callable();
  } catch (error) {
    isErrorThrown = true;

    if (!(error instanceof HologramMatchError)) {
      isAnyAssertFailed = true;
    } else if (!Interpreter.isStrictlyEqual(error.value, value)) {
      isAnyAssertFailed = true;
    }
  }

  if (!isErrorThrown || isAnyAssertFailed) {
    assert.fail(
      `expected HologramMatchError with value: ${Interpreter.inspect(value)}`,
    );
  }
}

export function linkModules() {
  globalThis.Erlang = Erlang;
  globalThis.Erlang_Lists = Erlang_Lists;
  globalThis.Erlang_Maps = Erlang_Maps;
  globalThis.Erlang_Persistent_Term = Erlang_Persistent_Term;
  globalThis.Erlang_Unicode = Erlang_Unicode;
  globalThis.Elixir_Enum = {};
  globalThis.Elixir_Kernel = Elixir_Kernel;
}

export function unlinkModules() {
  delete globalThis.Erlang;
  delete globalThis.Erlang_Lists;
  delete globalThis.Erlang_Maps;
  delete globalThis.Erlang_Persistent_Term;
  delete globalThis.Erlang_Unicode;
  delete globalThis.Elixir_Enum;
  delete globalThis.Elixir_Kernel;
}

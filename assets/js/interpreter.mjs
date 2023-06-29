"use strict";

// See: https://www.blazemeter.com/blog/the-correct-way-to-import-lodash-libraries-a-benchmark
import isEqual from "lodash/isEqual.js";
import uniqWith from "lodash/uniqWith.js";

import Hologram from "./hologram.mjs";
import Type from "./type.mjs";
import Utils from "./utils.mjs";

export default class Interpreter {
  static callAnonymousFunction(fun, argsArray) {
    const args = Type.list(argsArray);

    for (const clause of fun.clauses) {
      const varsClone = Utils.clone(fun.vars);
      const pattern = Type.list(clause.params);

      try {
        if (
          Interpreter.matchOperator(pattern, args, varsClone) &&
          Interpreter.#evaluateGuard(clause.guard, varsClone)
        ) {
          return clause.body(varsClone);
        }
      } catch {}
    }

    // TODO: include parent module and function info, once context for error reporting is implemented.
    const message = "no function clause matching in anonymous fn/" + fun.arity;
    return Interpreter.#raiseFunctionClauseError(message);
  }

  static case(condition, clauses, vars) {
    for (const clause of clauses) {
      const varsClone = Utils.clone(vars);

      try {
        Interpreter.matchOperator(clause.head, condition, varsClone);

        if (Interpreter.#evaluateGuard(clause.guard, varsClone) === false) {
          continue;
        }
        return clause.body(varsClone);
      } catch {
        continue;
      }
    }

    const message = "no case clause matching: " + Hologram.inspect(condition);

    return Interpreter.#raiseCaseClauseError(message);
  }

  static comprehension(generators, filters, collectable, unique, mapper, vars) {
    const generatorsCount = generators.length;

    const sets = generators.map(
      (generator) => Elixir_Enum.to_list(generator.enumerable).data
    );

    let items = Utils.cartesianProduct(sets).reduce((acc, combination) => {
      const varsClone = Utils.clone(vars);

      for (let i = 0; i < generatorsCount; ++i) {
        try {
          Interpreter.matchOperator(
            generators[i].match,
            combination[i],
            varsClone
          );

          if (
            Interpreter.#evaluateGuard(generators[i].guard, varsClone) === false
          ) {
            return acc;
          }
        } catch {
          return acc;
        }
      }

      for (const filter of filters) {
        if (Type.isFalsy(filter(varsClone))) {
          return acc;
        }
      }

      acc.push(mapper(varsClone));
      return acc;
    }, []);

    if (unique) {
      items = uniqWith(items, Interpreter.isStrictlyEqual);
    }

    return Elixir_Enum.into(Type.list(items), collectable);
  }

  static cond(clauses, vars) {
    for (const clause of clauses) {
      const varsClone = Utils.clone(vars);

      if (Type.isTruthy(clause.condition(varsClone))) {
        return clause.body(varsClone);
      }
    }

    return Interpreter.#raiseCondClauseError();
  }

  static consOperator(left, right) {
    return Type.list([left].concat(right.data));
  }

  static defineFunction(moduleName, functionName, clauses) {
    if (!globalThis[moduleName]) {
      globalThis[moduleName] = {};
    }

    globalThis[moduleName][functionName] = function () {
      const args = Type.list(arguments);
      const arity = arguments.length;

      if (!Interpreter.#isArityDefined(clauses, arity)) {
        Interpreter.#raiseUndefinedFunctionError(
          moduleName,
          functionName,
          arity
        );
      }

      for (const clause of clauses) {
        const vars = {};
        const pattern = Type.list(clause.params);

        try {
          Interpreter.matchOperator(pattern, args, vars);

          if (Interpreter.#evaluateGuard(clause.guard, vars)) {
            return clause.body(vars);
          }
        } catch {}
      }

      const inspectedModuleName = Hologram.inspectModuleName(moduleName);
      const message = `no function clause matching in ${inspectedModuleName}.${functionName}/${arity}`;
      Interpreter.#raiseFunctionClauseError(message);
    };
  }

  static dotOperator(left, right) {
    // if left argument is a boxed atom, treat the operator as a remote function call
    if (Type.isAtom(left)) {
      return Hologram.module(left)[right.value]();
    }

    // otherwise treat the operator as map key access
    return Erlang_maps.get(right, left);
  }

  static isStrictlyEqual(left, right) {
    if (left.type !== right.type) {
      return false;
    }

    return isEqual(left, right);
  }

  // vars.__matchedVars__ keeps track of already pattern matched variables' values,
  // which enables to fail pattern matching if the variables with the same name
  // are being pattern matched to different values.
  //
  // right param is before left param, because we need the right arg evaluated before left arg.
  static matchOperator(right, left, vars, rootMatchOperator = true) {
    if (!vars.__matchedVars__) {
      vars.__matchedVars__ = {};
    }

    try {
      if (Type.isMatchPlaceholder(left)) {
        return Interpreter.#handleMatchOperatorResult(
          right,
          vars,
          rootMatchOperator
        );
      }

      if (Type.isVariablePattern(left)) {
        if (vars.__matchedVars__[left.name]) {
          if (
            !Interpreter.isStrictlyEqual(vars.__matchedVars__[left.name], right)
          ) {
            throw new Error("__match_error__");
          }
        } else {
          vars[left.name] = right;
          vars.__matchedVars__[left.name] = right;
        }

        return Interpreter.#handleMatchOperatorResult(
          right,
          vars,
          rootMatchOperator
        );
      }

      if (Type.isConsPattern(left)) {
        if (!Type.isList(right) || Erlang.length(right).value === 0n) {
          throw new Error("__match_error__");
        }

        const rightHead = Erlang.hd(right);
        const rightTail = Erlang.tl(right);

        Interpreter.matchOperator(rightHead, left.head, vars, false);
        Interpreter.matchOperator(rightTail, left.tail, vars, false);

        return Interpreter.#handleMatchOperatorResult(
          right,
          vars,
          rootMatchOperator
        );
      }

      if (left.type !== right.type) {
        throw new Error("__match_error__");
      }

      if (Type.isList(left) || Type.isTuple(left)) {
        const count = Elixir_Enum.count(left).value;

        for (let i = 0; i < count; ++i) {
          Interpreter.matchOperator(right.data[i], left.data[i], vars, false);
        }

        return Interpreter.#handleMatchOperatorResult(
          right,
          vars,
          rootMatchOperator
        );
      }

      if (Type.isMap(left)) {
        for (const [key, value] of Object.entries(left.data)) {
          Interpreter.matchOperator(right.data[key][1], value[1], vars, false);
        }

        return Interpreter.#handleMatchOperatorResult(
          right,
          vars,
          rootMatchOperator
        );
      }

      if (!Interpreter.isStrictlyEqual(left, right)) {
        throw new Error("__match_error__");
      }

      return Interpreter.#handleMatchOperatorResult(
        right,
        vars,
        rootMatchOperator
      );
    } catch {
      Interpreter.raiseMatchError(right);
    }
  }

  static raiseMatchError(right) {
    const message =
      "no match of right hand side value: " + Hologram.inspect(right);

    return Hologram.raiseError("MatchError", message);
  }

  static #evaluateGuard(guard, vars) {
    if (guard === null) {
      return true;
    }

    return Type.isTrue(guard(vars));
  }

  static #handleMatchOperatorResult(result, vars, rootMatchOperator) {
    if (rootMatchOperator) {
      delete vars.__matchedVars__;
    }

    return result;
  }

  static #isArityDefined(clauses, arity) {
    return clauses.some((clause) => clause.params.length === arity);
  }

  static #raiseCaseClauseError(message) {
    return Hologram.raiseError("CaseClauseError", message);
  }

  static #raiseCondClauseError() {
    return Hologram.raiseError(
      "CondClauseError",
      "no cond clause evaluated to a truthy value"
    );
  }

  static #raiseFunctionClauseError(message) {
    return Hologram.raiseError("FunctionClauseError", message);
  }

  static #raiseUndefinedFunctionError(moduleName, functionName, arity) {
    // TODO: include info about available alternative arities
    const inspectedModuleName = Hologram.inspectModuleName(moduleName);
    const message = `function ${inspectedModuleName}.${functionName}/${arity} is undefined or private`;

    return Hologram.raiseError("UndefinedFunctionError", message);
  }
}

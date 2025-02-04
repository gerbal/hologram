"use strict";

import {
  assert,
  assertBoxedError,
  linkModules,
  sinon,
  unlinkModules,
} from "../../../assets/js/test_support.mjs";

import Erlang_Unicode from "../../../assets/js/erlang/unicode.mjs";
import HologramInterpreterError from "../../../assets/js/errors/interpreter_error.mjs";
import Type from "../../../assets/js/type.mjs";

before(() => linkModules());
after(() => unlinkModules());

// IMPORTANT!
// Each JavaScript test has a related Elixir consistency test in test/elixir/hologram/ex_js_consistency/erlang/unicode_test.exs
// Always update both together.

describe("characters_to_binary/1", () => {
  let prevCharactersToBinaryFun;

  beforeEach(() => {
    prevCharactersToBinaryFun =
      globalThis.Erlang_Unicode["characters_to_binary/3"];
  });

  afterEach(() => {
    globalThis.Erlang_Unicode["characters_to_binary/3"] =
      prevCharactersToBinaryFun;
  });

  it("delegates to :unicode.characters_to_binary/3", () => {
    const stub = sinon
      .stub(Erlang_Unicode, "characters_to_binary/3")
      .callsFake((_input, _inputEncoding, _outputEncoding) => "dummy");

    const input = Type.bitstring("abc");
    const encodingOpt = Type.atom("utf8");

    Erlang_Unicode["characters_to_binary/1"](input);

    sinon.assert.calledWith(stub, input, encodingOpt, encodingOpt);
  });
});

describe("characters_to_binary/3", () => {
  const utf8Atom = Type.atom("utf8");

  it("input is an empty list", () => {
    const result = Erlang_Unicode["characters_to_binary/3"](
      Type.list([]),
      utf8Atom,
      utf8Atom,
    );

    assert.deepStrictEqual(result, Type.bitstring(""));
  });

  it("input is a list of ASCII code points", () => {
    const input = Type.list([
      Type.integer(97), // a
      Type.integer(98), // b
      Type.integer(99), // c
    ]);

    const result = Erlang_Unicode["characters_to_binary/3"](
      input,
      utf8Atom,
      utf8Atom,
    );

    const expected = {
      type: "bitstring",
      // prettier-ignore
      bits: new Uint8Array([
              0, 1, 1, 0, 0, 0, 0, 1,
              0, 1, 1, 0, 0, 0, 1, 0,
              0, 1, 1, 0, 0, 0, 1, 1
            ]),
    };

    assert.deepStrictEqual(result, expected);
  });

  it("input is a list of non-ASCII code points (Chinese)", () => {
    const input = Type.list([
      Type.integer(20840), // 全
      Type.integer(24687), // 息
      Type.integer(22270), // 图
    ]);

    const result = Erlang_Unicode["characters_to_binary/3"](
      input,
      utf8Atom,
      utf8Atom,
    );

    const expected = {
      type: "bitstring",
      // prettier-ignore
      bits: new Uint8Array([
          1, 1, 1, 0, 0, 1, 0, 1,
          1, 0, 0, 0, 0, 1, 0, 1,
          1, 0, 1, 0, 1, 0, 0, 0,
          1, 1, 1, 0, 0, 1, 1, 0,
          1, 0, 0, 0, 0, 0, 0, 1,
          1, 0, 1, 0, 1, 1, 1, 1,
          1, 1, 1, 0, 0, 1, 0, 1,
          1, 0, 0, 1, 1, 0, 1, 1,
          1, 0, 1, 1, 1, 1, 1, 0
        ]),
    };

    assert.deepStrictEqual(result, expected);
  });

  it("input is a binary bitstring", () => {
    const input = Type.bitstring("abc");

    const result = Erlang_Unicode["characters_to_binary/3"](
      input,
      utf8Atom,
      utf8Atom,
    );

    assert.deepStrictEqual(result, input);
  });

  it("input is a non-binary bitstring", () => {
    assertBoxedError(
      () =>
        Erlang_Unicode["characters_to_binary/3"](
          Type.bitstring([1, 0, 1]),
          utf8Atom,
          utf8Atom,
        ),
      "ArgumentError",
      "errors were found at the given arguments:\n\n  * 1st argument: not valid character data (an iodata term)\n",
    );
  });

  it("input is a list of binary bitstrings", () => {
    const input = Type.list([
      Type.bitstring("abc"),
      Type.bitstring("def"),
      Type.bitstring("ghi"),
    ]);

    const result = Erlang_Unicode["characters_to_binary/3"](
      input,
      utf8Atom,
      utf8Atom,
    );

    const expected = Type.bitstring("abcdefghi");

    assert.deepStrictEqual(result, expected);
  });

  it("input is a list of non-binary bitstrings", () => {
    const input = Type.list([
      Type.bitstring([1, 1, 0]),
      Type.bitstring([1, 0, 1]),
      Type.bitstring([0, 1, 1]),
    ]);

    assertBoxedError(
      () => Erlang_Unicode["characters_to_binary/3"](input, utf8Atom, utf8Atom),
      "ArgumentError",
      "errors were found at the given arguments:\n\n  * 1st argument: not valid character data (an iodata term)\n",
    );
  });

  it("input is a list of code points mixed with binary bitstrings", () => {
    const input = Type.list([
      Type.integer(97), // a
      Type.bitstring("bcd"),
      Type.integer(101), // e
      Type.bitstring("fgh"),
      Type.integer(105), // i
    ]);

    const result = Erlang_Unicode["characters_to_binary/3"](
      input,
      utf8Atom,
      utf8Atom,
    );

    const expected = Type.bitstring("abcdefghi");

    assert.deepStrictEqual(result, expected);
  });

  it("input is a list of elements of types other than a list or a bitstring", () => {
    const input = Type.list([Type.float(123.45), Type.atom("abc")]);

    assertBoxedError(
      () => Erlang_Unicode["characters_to_binary/3"](input, utf8Atom, utf8Atom),
      "ArgumentError",
      "errors were found at the given arguments:\n\n  * 1st argument: not valid character data (an iodata term)\n",
    );
  });

  it("input is not a list or a bitstring", () => {
    assertBoxedError(
      () =>
        Erlang_Unicode["characters_to_binary/3"](
          Type.atom("abc"),
          utf8Atom,
          utf8Atom,
        ),
      "ArgumentError",
      "errors were found at the given arguments:\n\n  * 1st argument: not valid character data (an iodata term)\n",
    );
  });

  it("input is a nested list", () => {
    const input = Type.list([
      Type.integer(97), // a
      Type.list([
        Type.integer(98), // b
        Type.list([
          Type.integer(99), // c
          Type.bitstring("def"),
          Type.integer(103), // g
        ]),
        Type.integer(104), // h
      ]),
      Type.integer(105), // i
    ]);

    const result = Erlang_Unicode["characters_to_binary/3"](
      input,
      utf8Atom,
      utf8Atom,
    );

    const expected = Type.bitstring("abcdefghi");

    assert.deepStrictEqual(result, expected);
  });

  it("input contains invalid code points", () => {
    const input = Type.list([
      Type.integer(97), // a
      Type.bitstring("bcd"),
      // Max Unicode code point value is 1,114,112
      Type.integer(1114113),
      Type.bitstring("efg"),
    ]);

    const result = Erlang_Unicode["characters_to_binary/3"](
      input,
      utf8Atom,
      utf8Atom,
    );

    const expected = Type.tuple([
      Type.atom("error"),
      Type.bitstring("abcd"),
      Type.list([Type.integer(1114113), Type.bitstring("efg")]),
    ]);

    assert.deepStrictEqual(result, expected);
  });

  // This is temporary, until the related TODO is implemented.
  it("input encoding is different than :utf8", () => {
    assert.throw(
      () =>
        Erlang_Unicode["characters_to_binary/3"](
          Type.list([]),
          Type.atom("utf16"),
          utf8Atom,
        ),
      HologramInterpreterError,
      "encodings other than utf8 are not yet implemented in Hologram",
    );
  });

  // This is temporary, until the related TODO is implemented.
  it("output encoding is different than :utf8", () => {
    assert.throw(
      () =>
        Erlang_Unicode["characters_to_binary/3"](
          Type.list([]),
          utf8Atom,
          Type.atom("utf16"),
        ),
      HologramInterpreterError,
      "encodings other than utf8 are not yet implemented in Hologram",
    );
  });
});

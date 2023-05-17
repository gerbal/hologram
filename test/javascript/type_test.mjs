"use strict";

import { assert, assertFrozen } from "../../assets/js/test_support.mjs";
import Type from "../../assets/js/type.mjs";

describe("atom()", () => {
  it("returns boxed atom value", () => {
    const result = Type.atom("test");
    const expected = { type: "atom", value: "test" };

    assert.deepStrictEqual(result, expected);
  });

  it("returns frozen object", () => {
    assertFrozen(Type.atom("test"));
  });
});

describe("encodeMapKey()", () => {
  it("encodes boxed atom value as map key", () => {
    const boxed = Type.atom("abc");
    const result = Type.encodeMapKey(boxed);

    assert.equal(result, "atom(abc)");
  });

  it("encodes boxed float value as map key", () => {
    const boxed = Type.float(1.23);
    const result = Type.encodeMapKey(boxed);

    assert.equal(result, "float(1.23)");
  });

  it("encodes boxed integer value as map key", () => {
    const boxed = Type.integer(123);
    const result = Type.encodeMapKey(boxed);

    assert.equal(result, "integer(123)");
  });

  it("encodes boxed list value as map key", () => {
    const boxed = Type.list([Type.integer(1), Type.atom("b")]);
    const result = Type.encodeMapKey(boxed);

    assert.equal(result, "list(integer(1),atom(b))");
  });

  it("encodes boxed string value as map key", () => {
    const boxed = Type.string("abc");
    const result = Type.encodeMapKey(boxed);

    assert.equal(result, "string(abc)");
  });
});

describe("encodePrimitiveTypeMapKey()", () => {
  it("encodes primitive type as map key", () => {
    const boxed = Type.atom("abc");
    const result = Type.encodePrimitiveTypeMapKey(boxed);

    assert.equal(result, "atom(abc)");
  });
});

describe("float()", () => {
  it("returns boxed float value", () => {
    const result = Type.float(1.23);
    const expected = { type: "float", value: 1.23 };

    assert.deepStrictEqual(result, expected);
  });

  it("returns frozen object", () => {
    assertFrozen(Type.float(1.0));
  });
});

describe("integer()", () => {
  it("returns boxed integer value", () => {
    const result = Type.integer(1);
    const expected = { type: "integer", value: 1 };

    assert.deepStrictEqual(result, expected);
  });

  it("returns frozen object", () => {
    assertFrozen(Type.integer(1));
  });
});

describe("list()", () => {
  let data, expected, result;

  beforeEach(() => {
    data = [Type.integer(1), Type.integer(2)];

    result = Type.list(data);
    expected = { type: "list", data: data };
  });

  it("returns boxed list value", () => {
    assert.deepStrictEqual(result, expected);
  });

  it("returns frozen object", () => {
    assertFrozen(result);
  });
});

describe("string()", () => {
  it("returns boxed string value", () => {
    const result = Type.string("test");
    const expected = { type: "string", value: "test" };

    assert.deepStrictEqual(result, expected);
  });

  it("returns frozen object", () => {
    assertFrozen(Type.string("test"));
  });
});

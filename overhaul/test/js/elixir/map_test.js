"use strict";

import {
  assert,
  assertBoxedFalse,
  assertBoxedTrue,
  assertFrozen,
  cleanup,
} from "../support/commons";
beforeEach(() => cleanup());

import Map from "../../../assets/js/hologram/elixir/map";
import Type from "../../../assets/js/hologram/type";

describe("get()", () => {
  let elems = {};
  elems[Type.atomKey("a")] = Type.integer(1);
  elems[Type.atomKey("b")] = Type.integer(2);
  const map = Type.map(elems);

  it("gets the value for a specific key in map if the given key exists in the given map", () => {
    const result = Map.get(map, Type.atom("b"));
    assert.deepStrictEqual(result, Type.integer(2));
  });

  it("returns boxed nil by default if the given key doesn't exist in the given map", () => {
    const result = Map.get(map, Type.atom("c"));
    assert.deepStrictEqual(result, Type.nil());
  });

  it("it returns the default_value arg if the given key doesn't exist in the given map and the default_value param is specified", () => {
    const result = Map.get(map, Type.atom("c"), Type.integer(9));
    assert.deepStrictEqual(result, Type.integer(9));
  });
});

describe("has_key$question()", () => {
  let elems = {};
  elems[Type.atomKey("a")] = Type.integer(1);
  elems[Type.atomKey("b")] = Type.integer(2);
  const map = Type.map(elems);

  it("returns boxed true if the given key exists in the given map", () => {
    const result = Map.has_key$question(map, Type.atom("b"));
    assertBoxedTrue(result);
  });

  it("returns boxed false if the given key doesn't exist in the given map", () => {
    const result = Map.has_key$question(map, Type.atom("c"));
    assertBoxedFalse(result);
  });
});

describe("keys()", () => {
  it("returns keys of a non-empty map", () => {
    let map = Type.map();
    map = Map.put(map, Type.atom("a"), Type.integer(1));
    map = Map.put(map, Type.atom("b"), Type.integer(2));

    const result = Map.keys(map);
    const expected = Type.list([Type.atom("a"), Type.atom("b")]);

    assert.deepStrictEqual(result, expected);
  });

  it("returns keys of an empty map", () => {
    const result = Map.keys(Type.map());
    assert.deepStrictEqual(result, Type.list());
  });

  it("returns frozen object", () => {
    const result = Map.keys(Type.map());
    assertFrozen(result);
  });
});

describe("put()", () => {
  let map1, map2, result;

  beforeEach(() => {
    let elems1 = {};
    elems1[Type.atomKey("a")] = Type.integer(1);
    elems1[Type.atomKey("b")] = Type.integer(2);
    map1 = Type.map(elems1);

    let elems2 = {};
    elems2[Type.atomKey("a")] = Type.integer(1);
    elems2[Type.atomKey("b")] = Type.integer(2);
    elems2[Type.atomKey("c")] = Type.integer(3);
    map2 = Type.map(elems2);

    result = Map.put(map1, Type.atom("c"), Type.integer(3));
  });

  it("adds the key-value pair to the map when the map doesn't contain the given key yet", () => {
    assert.deepStrictEqual(result, map2);
  });

  it("adds the key-value pair to the map when the map already contains the given key", () => {
    const result = Map.put(map2, Type.atom("c"), Type.integer(3));
    assert.deepStrictEqual(result, map2);
  });

  it("clones the orignal map object", () => {
    assert.notEqual(result, map1);
  });

  it("returns frozen object", () => {
    assertFrozen(result);
  });
});

describe("to_list()", () => {
  it("converts empty boxed map to empty boxed list", () => {
    const map = Type.map();

    const result = Map.to_list(map);
    const expected = Type.list();

    assert.deepStrictEqual(result, expected);
  });

  it("converts non-empty boxed map to boxed list consisting of {key, value} tuples", () => {
    let map = Type.map();
    map = Map.put(map, Type.atom("a"), Type.integer(1));
    map = Map.put(map, Type.string("b"), Type.float(2.0));

    const result = Map.to_list(map);

    const expectedData = [
      Type.tuple([Type.atom("a"), Type.integer(1)]),
      Type.tuple([Type.string("b"), Type.float(2.0)]),
    ];

    const expected = Type.list(expectedData);

    assert.deepStrictEqual(result, expected);
  });
});

"use strict";

export default class Hologram {
  static deserialize(json) {
    return JSON.parse(json, (_key, value) => {
      if (typeof value === "string" && /^__bigint__:-?\d+$/.test(value)) {
        return BigInt(value.substring(11, value.length));
      }
      return value;
    });
  }

  static module(alias) {
    const aliasStr = alias.value;
    let prefixedAliasStr;

    if (aliasStr === "erlang") {
      prefixedAliasStr = "Erlang";
    } else {
      prefixedAliasStr =
        aliasStr.charAt(0).toLowerCase() === aliasStr.charAt(0)
          ? "Erlang_" + aliasStr.charAt(0).toUpperCase() + aliasStr.slice(1)
          : aliasStr;
    }

    const className = prefixedAliasStr.replace(/\./g, "_");

    return Hologram[className];
  }

  static serialize(term) {
    return JSON.stringify(term, (_key, value) =>
      typeof value === "bigint" ? `__bigint__:${value.toString()}` : value
    );
  }
}

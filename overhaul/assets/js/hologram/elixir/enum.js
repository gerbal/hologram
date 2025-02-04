"use strict";

import { HologramNotImplementedError } from "../errors";
import Map from "./map"
import Type from "../type";
import Utils from "../utils";

export default class Enum {
  static concat(left, right) {
    const leftList = Enum.to_list(left)
    const rightList = Enum.to_list(right)

    return Type.list(leftList.data.concat(rightList.data))
  }

  // TODO: support Enum.count/2 and any data type that supports Enumerable protocol
  static count(enumerable) {
    return Type.integer(enumerable.data.length)
  }

  static member$question(enumerable, elem) {
    switch (enumerable.type) {
      case "list":
        if (enumerable.data.find(el => Utils.isEqual(el, elem))) {
          return Type.boolean(true)
        } else {
          return Type.boolean(false)
        }

      default: 
        const message = `Enum.member$question(): enumerable = ${JSON.stringify(enumerable)}, elem = ${JSON.stringify(elem)}`
        throw new HologramNotImplementedError(message)
    }
  }

  static reduce(enumerable, initialAcc, fun) {
    const reducer = (acc, elem) => fun.callback(elem, acc)
    return enumerable.data.reduce(reducer, initialAcc);
  }
  
  static to_list(enumerable) {
    switch (enumerable.type) {
      case "list":
        return enumerable

      case "map":
        const data = Map.keys(enumerable).data.reduce((acc, key) => {
          acc.push(Type.tuple([key, Map.get(enumerable, key)]))
          return acc
        }, [])
        return Type.list(data)

      default: 
        const message = `Enum.to_list(): enumerable = ${JSON.stringify(enumerable)}`
        throw new HologramNotImplementedError(message)      
    }
  }
}
"use strict";

import Runtime from "./runtime"
import Target from "./target"
import Type from "./type"
import Utils from "./utils"

import Map from "./elixir/map"

export default class Store {
  static componentStateRegistry = {}

  static hydrate(serializedState) {
    const state = Utils.eval(serializedState)
    
    // DEFER: use Kernel.put_in/3 here
    let context = Map.get(state, Type.atom("context"))
    context = Map.put(context, Type.atom("__state__"), Type.string(serializedState))

    Store.hydrateLayout(context)
    Store.hydratePage(state, context)
  }

  static hydrateLayout(context) {
    let state = Runtime.getLayoutClass().init()
    state = Map.put(state, Type.atom("context"), context)

    Store.setComponentState(Target.TYPE.layout, state)
  }

  static hydratePage(state, context) {
    state = Map.put(state, Type.atom("context"), context)
    Store.setComponentState(Target.TYPE.page, state)
  }

  static getComponentState(componentId) {
    const state = Store.componentStateRegistry[componentId]
    return state ? state : null
  }

  static getLayoutState() {
    return Store.getComponentState(Target.TYPE.layout)
  }

  static getPageState() {
    return Store.getComponentState(Target.TYPE.page)
  }

  static resolveComponentState(componentId) {
    if (componentId) {
      let state = Store.getComponentState(componentId)

      if (!state) {
        state = Runtime.getComponentClass(componentId).init()
        Store.setComponentState(componentId, state)
      }

      return state

    } else {
      return Type.map({})
    }
  }

  static setComponentState(componentId, state) {
    Store.componentStateRegistry[componentId] = state
  }
}
"use strict";

import Runtime from "./runtime"
import Target from "./target"
import Type from "./type"

import Map from "./elixir/map"

export default class Store {
  static componentStateRegistry = {}

  static buildContext(pageClassName, digest) {
    let context = Type.map();
    context = Map.put(context, Type.atom("__class__"), Type.string(pageClassName));
    context = Map.put(context, Type.atom("__digest__"), Type.string(digest));
    context = Map.put(context, Type.atom("__state__"), Type.string("'placeholder'"));

    return context
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

  static hydrate(pageClassName, digest, state) {    
    const context = Store.buildContext(pageClassName, digest)
    
    Store.hydrateLayout(state, context)
    Store.hydratePage(state, context)
    Store.hydrateComponents(state)
  }

  static hydrateComponents(state) {
    Map.keys(state).data.forEach(key => {
      if (key.value !== Target.TYPE.page && key.value !== Target.TYPE.layout) {
        const componentState = Map.get(state, key)
        Store.setComponentState(key.value, componentState)
      }
    })
  }

  static hydrateLayout(state, context) {
    let layoutState = Map.get(state, Type.atom("layout"))
    layoutState = Map.put(layoutState, Type.atom("__context__"), context)

    Store.setComponentState(Target.TYPE.layout, layoutState)
  }

  static hydratePage(state, context) {
    let pageState = Map.get(state, Type.atom("page"))
    pageState = Map.put(pageState, Type.atom("__context__"), context)

    Store.setComponentState(Target.TYPE.page, pageState)
  }

  static resolveComponentState(componentId, props) {
    if (componentId) {
      let state = Store.getComponentState(componentId)

      if (!state) {
        state = Runtime.getComponentClass(componentId).init(props)
        Store.setComponentState(componentId, state)
      }

      return state

    } else {
      return Type.map()
    }
  }

  static setComponentState(componentId, state) {
    Store.componentStateRegistry[componentId] = state
  }
}
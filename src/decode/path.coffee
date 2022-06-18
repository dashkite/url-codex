import * as Parse from "@dashkite/parse"
import * as Fn from "@dashkite/joy/function"
import * as It from "@dashkite/joy/iterable"

import * as Common from "../parsers/common"

import {
  prefix
  build as _build
  optional
} from "./helpers"


# Path parser helpers

component = ( variable ) ->
  Parse.pipe [
    Common.component
    Parse.tag variable
  ]

list = ( variable ) ->
  Parse.pipe [
    Parse.list ( Parse.text "/" ), Common.component
    Parse.tag variable
  ]

builders = ( bindings, state ) ->

  literal: ( text ) ->
    state.optional = false
    Parse.skip Parse.text text

  default: ( variable ) ->
    state.optional = false
    component variable

  "?": ( variable ) ->
    bindings[ variable ] = null
    Parse.optional component variable

  "*": ( variable ) ->
    bindings[ variable ] = []
    Parse.optional list variable

  "+": ( variable ) ->
    state.optional = false
    bindings[ variable ] = []
    list variable

build = Fn.pipe [
  builders
  _build
]

visitor = ( bindings ) ->
  state = optional: true
  Fn.pipe [
    It.map build bindings, state
    Parse.join Parse.text "/"
    prefix Parse.skip Parse.text "/"
    optional state
  ]  

export { visitor }
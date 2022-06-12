import * as Parse from "@dashkite/parse"
import * as Fn from "@dashkite/joy/function"
import * as It from "@dashkite/joy/iterable"

import * as Common from "../parsers/common"

import {
  prefix
  build as _build
  optional
} from "./helpers"

# Query parser helpers

assignment = ( variable ) ->
  Parse.pipe [
    Parse.all [
      Parse.skip Parse.text variable
      Parse.skip Parse.text "="
      Common.value
    ]
    Parse.first
    Parse.tag variable
  ]

builders = ( bindings, state ) ->

  literal: ({ key, value }) ->
    state.optional = false
    Parse.skip Parse.all [
      Parse.text key
      Parse.text "="
      Parse.text value
    ]

  default: ( variable ) ->
    state.optional = false
    assignment variable

  "?": ( variable ) ->
    bindings[ variable ] = null
    assignment variable

  "*": ( variable ) ->
    bindings[ variable ] = []
    assignment variable

  "+": ( variable ) ->
    state.optional = false
    bindings[ variable ] = []
    assignment variable

build = Fn.pipe [
  builders
  _build
]

visitor = ( bindings ) ->
  state = optional: true
  Fn.pipe [
    It.map build bindings, state
    Parse.any
    Parse.list Parse.text "&"
    prefix Parse.skip Parse.text "?"
    optional state
  ]

export { visitor }
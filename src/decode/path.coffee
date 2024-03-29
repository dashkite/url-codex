import * as Parse from "@dashkite/parse"
import * as Fn from "@dashkite/joy/function"
import * as It from "@dashkite/joy/iterable"

import * as Common from "../parsers/common"

import {
  evaluate
} from "./helpers"


# Path parser helpers

delimiter = Parse.text "/"

component = ( variable ) ->
  Parse.pipe [
    Common.component
    Parse.tag variable
  ]

list = ( variable ) ->
  Parse.pipe [
    Parse.list delimiter, Common.component
    Parse.tag variable
  ]

handlers = ( bindings, state ) ->

  literal: ( text ) ->
    state.optional = false
    Parse.skip Parse.pipe [
      Common.component
      Parse.test text, ( value ) -> value == text
    ]

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

visitor = ( bindings ) ->
  state = optional: true
  Fn.pipe [
    It.map evaluate handlers bindings, state
    ( patterns ) ->
      Parse.all [
        Parse.skip delimiter
        Parse.pipe [
          Parse.join delimiter, patterns
          Parse.flatten
          Parse.merge
        ]
      ]
    ( parser ) -> if state.optional then Parse.optional parser else parser
  ]  

export { visitor }
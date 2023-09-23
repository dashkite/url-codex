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
      Parse.all [
        Parse.skip delimiter
        Common.component
      ]
      Parse.first
      Parse.test text, ( value ) -> value == text
    ]

  default: ( variable ) ->
    state.optional = false
    Parse.pipe [
      Parse.all [
        Parse.skip delimiter
        component variable
      ]
      Parse.first
    ]
    

  "?": ( variable ) ->
    bindings[ variable ] = null
    Parse.optional Parse.all [
      Parse.skip delimiter
      component variable
    ]

  "*": ( variable ) ->
    bindings[ variable ] = []
    Parse.optional Parse.all [
      Parse.skip delimiter
      list variable
    ]

  "+": ( variable ) ->
    state.optional = false
    bindings[ variable ] = []
    Parse.all [
      Parse.skip delimiter
      list variable
    ]

visitor = ( bindings ) ->
  state = optional: true
  Fn.pipe [
    It.map evaluate handlers bindings, state
    ( patterns ) ->
      Parse.pipe [
        Parse.all [
          patterns...
          Parse.skip Parse.optional delimiter
        ]
        Parse.flatten
        Parse.merge
      ]
    ( parser ) -> if state.optional then Parse.optional parser else parser
  ]  

export { visitor }
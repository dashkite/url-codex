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
    elements = [ Common.component ]
    if ( ! ( state.first && ( ! state.absolute ) ) )
      elements.unshift Parse.skip delimiter
    state.first = false
    Parse.skip Parse.pipe [
      Parse.all elements
      Parse.first
      Parse.test text, ( value ) -> value == text
    ]

  default: ( variable ) ->
    state.optional = false
    elements = [ component variable ]
    if ( ! ( state.first && ( ! state.absolute ) ) )
      elements.unshift Parse.skip delimiter
    state.first = false
    Parse.pipe [
      Parse.all elements
      Parse.first
    ]
    

  "?": ( variable ) ->
    bindings[ variable ] = null
    elements = [ component variable ]
    if ( ! ( state.first && ( ! state.absolute ) ) )
      elements.unshift Parse.skip delimiter
    state.first = false
    Parse.optional Parse.all elements

  "*": ( variable ) ->
    bindings[ variable ] = []
    elements = [ list variable ]
    if ( ! ( state.first && ( ! state.absolute ) ) )
      elements.unshift Parse.skip delimiter
    state.first = false
    Parse.optional Parse.all elements

  "+": ( variable ) ->
    state.optional = false
    bindings[ variable ] = []
    elements = [ list variable ]
    if ( ! ( state.first && ( ! state.absolute ) ) )
      elements.unshift Parse.skip delimiter
    state.first = false
    Parse.all elements

visitor = ( bindings, absolute ) ->
  state =
    optional: true
    first: true
    absolute: absolute
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
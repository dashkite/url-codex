import * as Parse from "@dashkite/parse"
import * as Fn from "@dashkite/joy/function"
import * as It from "@dashkite/joy/iterable"

import * as Common from "../parsers/common"

import {
  evaluate
} from "./helpers"

# Query parser helpers

start = Parse.text "?"

delimiter = Parse.text "&"

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

group = ( variable ) ->
  Parse.pipe [
    Parse.list delimiter, Parse.pipe [
      Parse.all [
        Common.symbol
        Parse.skip Parse.text "="
        Common.value
      ]
      Parse.map ([ key, value ]) -> [ key ]: value
    ]
    Parse.merge
    Parse.tag variable
  ]

handlers = ( bindings, state ) ->

  literal: ({ key, value }) ->
    state.optional = false
    Parse.skip Parse.all [
      Parse.text key
      Parse.text "="
      Parse.text value
    ]

  default: ( variable ) ->
    state.optional = false
    state.required.push variable
    assignment variable

  "?": ( variable ) ->
    bindings[ variable ] = null
    assignment variable

  "*": ( variable ) ->
    bindings[ variable ] = {}
    group variable

  "+": ( variable ) ->
    state.optional = false
    state.required.push variable
    bindings[ variable ] = {}
    group variable

visitor = ( bindings ) ->
  state = 
    optional: true
    required: []
  Fn.pipe [
    It.map evaluate handlers bindings, state
    ( patterns ) ->
      Parse.all [
        Parse.skip start
        Parse.pipe [
          Parse.list delimiter, Parse.any patterns
          Parse.flatten
          Parse.merge
          # TODO we need a better version of verify
          #      where we can tailor the error message
          #      based on which parameter is missing
          Parse.verify 
            expected: "required query parameters"
            ( value ) ->
              state.required.every (variable) -> value[ variable ]?
        ]
      ]
    ( parser ) -> if state.optional then Parse.optional parser else parser
  ]


export { visitor }
import * as Parse from "@dashkite/parse"
import * as Fn from "@dashkite/joy/function"
import * as It from "@dashkite/joy/iterable"

import * as Common from "../parsers/common"

import {
  prefix
  build as _build
  optional
} from "./helpers"

assign = Fn.curry ( state, pattern ) ->
  Parse.pipe [
    Parse.assign state
    pattern
  ]

# - name: wildcard path (+)
#     template: https://acme.org/{foo+}
#     url: https://acme.org/abc/def
#     bindings:
#       foo: [ abc, def ]

dlist = ( delimiter, item ) ->
  item = Parse.pattern item
  delimiter = Parse.pattern delimiter
  (c) ->
    state = c
    states = []
    value = []
    m = undefined
    while state.rest.length > 0
      if !( m = item state ).error?
        value.push m.value if m.value?
        data = { state.data..., states }
        state = { state..., m..., value, data }
        states.unshift state
      else break

      if !( n = delimiter state ).error?
        state = { state..., n..., value }
      else break

    # if we end on an item parsing error
    if m.error?
      # try to backtrack
      if states.length > 1
        states.shift()
      else
        # or just return the error
        { c, error: m.error }
    else
      # otherwise, we always return the last item parsed
      # either because we failed to parse a delimiter or
      # we reached the end of the input after parsing the
      # delimiter, so we "put it back" because it might
      # belong to the next combinator
      states[ 0 ]

decrement = Fn.tee ( c ) -> c.data.leave--

leave = ( c ) ->
  do ({ leave } = {}) ->
    { states, leave } = c.data
    console.log { leave, states: states?.length }
    if ( leave > 0 ) && states?[ leave - 1 ]?
      states[ leave - 1 ]
    else
      c

save = Fn.tee ( c ) ->
  { states } = c.data
  if states?.unshift?
    states.unshift c
  else
    c.data.states = [ c ]

# Path parser helpers

component = ( variable ) ->
  Parse.pipe [
    Common.name
    Parse.tag variable
  ]

list = ( variable ) ->
  Parse.pipe [
    dlist ( Parse.text "/" ), Common.component
    Parse.tag variable
  ]

builders = ( bindings, state ) ->

  literal: ( text ) ->
    state.optional = false
    state.leave++
    Parse.pipe [
      Parse.skip Parse.text text
      decrement
    ]

  default: ( variable ) ->
    state.optional = false
    state.leave++
    Parse.pipe [
      component variable
      decrement
    ]

  "?": ( variable ) ->
    bindings[ variable ] = null
    Parse.optional Parse.pipe [
      save
      component variable
      leave
    ]

  "*": ( variable ) ->
    bindings[ variable ] = []
    Parse.optional Parse.pipe [
      list variable
      leave
    ]

  "+": ( variable ) ->
    state.optional = false
    state.leave++
    bindings[ variable ] = []
    Parse.pipe [
      list variable
      decrement
      leave
    ]

build = Fn.pipe [
  builders
  _build
]

visitor = ( bindings ) ->
  state = 
    optional: true
    leave: 0
  Fn.pipe [
    It.map build bindings, state
    Parse.join Parse.text "/"
    prefix Parse.skip Parse.text "/"
    optional state
    assign state
  ]  

export { visitor }
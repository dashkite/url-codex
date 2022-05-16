import * as Parse from "@dashkite/parse"
import * as Fn from "@dashkite/joy/function"
import * as Type from "@dashkite/joy/type"
import { generic } from "@dashkite/joy/generic"
import JSONQuery from "json-query"

start = Parse.text "${"
end = Parse.text "}"
escape = Parse.text "\\"
symbol = Parse.re /^./

escaped = Parse.all [
  Parse.skip escape
  symbol
]

textSymbol = Parse.any [
  escaped
  Parse.negate start
]

expressionSymbol = Parse.any [
  escaped
  Parse.negate end
]

text = Parse.pipe [
  Parse.many textSymbol
  Parse.cat
  Parse.tag "text"
]

expression = Parse.pipe [
  Parse.between start, end, Parse.many expressionSymbol
  Parse.cat
  Parse.trim
  Parse.tag "expression"
]

parse = Parse.parser Parse.pipe [
  Parse.many Parse.any [
    expression
    text
  ]
]

query = ( expression, data ) ->
  ( JSONQuery expression, { data } )?.value

concatenate = ( result, value ) ->
  if result?
    "#{result}#{value}"
  else
    # don't convert to string
    # unless we are concatenating
    value

collate = ( context ) ->
  ( result, [ key, value ]) ->
    result[ key ] = expand value, context
    result

expand = generic 
  name: "expand"
  default: Fn.identity

generic expand, Type.isObject, Type.isObject, ( object, context ) ->
  Object.entries object
    .reduce ( collate context ), {}

generic expand, Type.isArray, Type.isObject, ( array, context ) ->
  expand value, context for value in array

generic expand, Type.isString, Type.isObject, ( text, context ) -> 
  result = null
  parse text
  .map ( block ) ->
    if block.text?
      block.text
    else
      query block.expression, context
  .reduce concatenate, null

export { expand, parse, query }
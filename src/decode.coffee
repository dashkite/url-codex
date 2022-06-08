import * as Fn from "@dashkite/joy/function"
import * as Obj from "@dashkite/joy/object"
import * as Parsers from "./parsers"

import {
  failure
  assert
} from "./helpers"

decodeComponents = ( bindings, template, source ) ->
  for component, i in template
    if component.expression?
      bindings[ component.expression.variable ] = do ->
        switch component.expression.modifier
          when undefined, null
            assert.isDefined source?[i], component.expression
            source[ i ] ? null
          when "?"
            source?[ i ] ? null
          when "+"
            assert.isDefined source?[i], component.expression
            source[ i..-1 ]
          when "*"
            source?[ i..-1 ] ? []
    else
      if component != source[i]
        throw failure "mismatched literal",
          template: component
          url: source[i]

createDecodingContext = ( template, url ) ->
  parsed:
    template: Parsers.template template
    url: Parsers.url url
  result: {}

decodeOrigin = Fn.tee ( context ) ->
  { parsed, result } = context
  decodeComponents result, 
    parsed.template.origin.domain,
    parsed.url.origin.domain

decodePath = Fn.tee ( context ) ->
  { parsed, result } = context
  # TODO is there a possible error condition here?
  if parsed.template.path?
    decodeComponents result, parsed.template.path, parsed.url.path

decodeQuery = Fn.tee ( context ) ->
  { parsed, result } = context
  # TODO is there a possible error condition here?
  if parsed.template.query?
    for component, i in parsed.template.query
      { key, value } = component
      if value.expression?
        result[ value.expression.variable ] = do ->
          switch value.expression.modifier
            when undefined, null
              entry = parsed.url.query?.find ( entry ) -> entry.key == key
              assert.isDefined entry, key
              entry.value
            when "?"
              entry = parsed.url.query?.find ( entry ) -> entry.key == key
              entry?.value ? null
            when "+"
              # TODO
              entries = parsed.url.query?.filter ( entry ) -> entry.key == key
              assert.isDefined entries, key
              if entries.length < 1
                throw failure "expected at least one", { key }
              entries.map ({ value }) -> value
            when "*"
              # TODO
              entries = parsed.url.query?.filter ( entry ) -> entry.key == key
              if entries?
                entries.map ({ value }) -> value
              else []

decode = Fn.pipe [
  createDecodingContext
  decodeOrigin
  decodePath
  decodeQuery
  Obj.get "result"
]

match = Fn.curry ( template, url ) ->
  try
    decode template, url
  catch error
    if error.message.startsWith "url-codex"
      undefined
    else
      throw error

export { decode, match }
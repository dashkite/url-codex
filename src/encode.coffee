import * as Fn from "@dashkite/joy/function"
import * as Type from "@dashkite/joy/type"
import * as Obj from "@dashkite/joy/object"
import * as It from "@dashkite/joy/iterable"
import * as Parsers from "./parsers"

import {
  failure
  assert
} from "./helpers"

evaluateExpression = Fn.curry ( bindings, { variable, modifier }) ->
  value = bindings[ variable ]
  switch modifier
    when undefined
      assert.isDefined value, { variable }
      assert.isString value, { variable }
      value
    when "?"
      if value?
        assert.isString value, { variable }
        value
      else
    when "+"
      assert.isDefined value, { variable }
      assert.isArray value, { variable }
      value
    when "*"
      if value?
        assert.isArray value, { variable }
        value

evaluateComponent = Fn.curry ( bindings, component ) ->
    if Type.isString component
      component
    else if component.key?
      # TODO handle array case
      "#{ component.key }=#{ evaluateComponent bindings, component.value }"
    else if component.expression?
      evaluateExpression bindings, component.expression

# TODO there's a bug in Arr.cat somehow
Arr =
  cat: ( result, value ) -> 
    [ result..., value... ]

  lift: ( value ) ->
    if Type.isArray value then value else [ value ]

evaluateComponents = ( components, bindings ) ->
  do Fn.pipe [
    -> components
    It.map evaluateComponent bindings
    It.select Type.isDefined
    It.map Arr.lift
    It.reduce Arr.cat, []
  ]

createEncodingContext = ( template, bindings ) ->
  parsed: Parsers.template template
  result: ""
  bindings: bindings

encodeText = Fn.curry Fn.rtee ( text, context ) ->
  context.result += text

encodeFrom = Fn.curry Fn.rtee ( getter, context ) ->
  context.result += getter context

encodeWhen = Fn.curry Fn.rtee ( predicate, action, context ) ->
  action context if predicate context
    
encodeDomain = encodeFrom ({ parsed, bindings }) ->
  It.join ".",
    evaluateComponents parsed.origin.domain, bindings

encodeOrigin = Fn.pipe [
  encodeFrom ({ parsed }) -> parsed.origin.protocol
  encodeText "://"
  encodeDomain
]

# TODO is there a way to keep from evaluating evaluateComponents twice?
#      (once here and once in encodePathComponents)
encodeHasPath = ({ parsed, bindings  }) ->
  ( evaluateComponents parsed.path, bindings ).length > 0

encodePathComponents = encodeFrom ({ parsed, bindings }) ->
  It.join "/",
    evaluateComponents parsed.path, bindings

encodePath = encodeWhen encodeHasPath, Fn.pipe [
  encodeText "/"
  encodePathComponents
]

encodeQueryComponents = encodeFrom ({ parsed, bindings }) ->
  It.join "&",
    evaluateComponents parsed.query, bindings

encodeHasQuery = ({ parsed  }) -> parsed.query?

encodeQuery = encodeWhen encodeHasQuery, Fn.pipe [
  encodeText "?"
  encodeQueryComponents
]

encode = Fn.pipe [
  createEncodingContext
  encodeOrigin
  encodePath
  encodeQuery
  Obj.get "result"
]

export { encode }
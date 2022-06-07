import * as Parse from "@dashkite/parse"
import * as Fn from "@dashkite/joy/function"
import * as Type from "@dashkite/joy/type"
import * as Obj from "@dashkite/joy/object"
import * as It from "@dashkite/joy/iterable"
import * as Text from "@dashkite/joy/text"
import { generic } from "@dashkite/joy/generic"
import { Messages } from "@dashkite/messages"
import failures from "./failures"

messages = Messages.create()
messages.add failures
messages.prefix = "url-codex"

failure = ( code, context ) ->
  messages.message code, context

variable = Parse.pipe [
  Parse.re /^[\w\-]+/
  Parse.tag "variable"
]

modifier = Parse.pipe [
  Parse.any [
    Parse.pipe [
      Parse.text "~"
      Parse.map -> "?"
    ]
    Parse.text "?"
    Parse.text "+"
    Parse.text "*"
  ]
  Parse.tag "modifier"
]

expression = Parse.pipe [
  Parse.between ( Parse.text "{" ), ( Parse.text "}"),
    Parse.pipe [
      Parse.all [
        variable
        Parse.optional modifier
      ]
      Parse.merge
    ]
  Parse.tag "expression"
]

protocol = Parse.pipe [
  Parse.text "https"
  Parse.tag "protocol"
]

scheme = Parse.pipe [
  Parse.all [ protocol, Parse.skip Parse.text ":" ]
  Parse.merge
]

domain = Parse.pipe [
  Parse.list ( Parse.text "." ), Parse.any [
    expression
    Parse.pipe [
      Parse.re /^[A-Za-z0-9\-]+/
      Parse.map Text.toLowerCase
    ]
  ]
  Parse.tag "domain"
]

origin = Parse.pipe [
  Parse.all [ 
    scheme
    Parse.skip Parse.text "//"
    domain 
  ]
  Parse.merge
  Parse.tag "origin"
]

component = Parse.re /^[\w\-\.\~\%\!\$\&\'\(\)\*\+\,\;\=\:\@]+/

path = Parse.pipe [
  Parse.many Parse.pipe [
    Parse.all [
      Parse.text "/"
      Parse.any [
        expression
        component
      ]
    ]
    Parse.second
  ]
  Parse.tag "path"
]

assignment = Parse.pipe [
  Parse.all [
    Parse.pipe [
      Parse.re /^[\w\-]+/
      Parse.tag "key"
    ]
    Parse.skip Parse.text "="
    Parse.pipe [
      Parse.re /^[\w\-\.\~\%\!\$\'\(\)\*\+\,\;\:\@\/\?]+/
      Parse.tag "value"
    ]
  ]
  Parse.merge
]

query = Parse.pipe [
  Parse.skip Parse.text "?"
  Parse.list ( Parse.skip Parse.text "&" ),
    Parse.any [ 
      Parse.pipe [
        expression
        Parse.map ({ expression }) ->
          key: expression.variable
          value: { expression }
      ]
      assignment 
    ]
  Parse.tag "query"
]

parse = Parse.parser Parse.pipe [
  Parse.all [
    origin
    Parse.optional path
    Parse.optional query 
  ]
  Parse.merge
]

assert = Fn.curry ( predicate, code, value, context ) ->
  if ! predicate value
    throw failure code, context

assertIsDefined = assert Type.isDefined, "missing value"
assertIsString = assert Type.isString, "expecting string"
assertIsArray = assert Type.isArray, "expecting array"

evaluateExpression = Fn.curry ( bindings, { variable, modifier }) ->
  value = bindings[ variable ]
  switch modifier
    when undefined
      assertIsDefined value, { variable }
      assertIsString value, { variable }
      value
    when "?"
      if value?
        assertIsString value, { variable }
        value
      else
    when "+"
      assertIsDefined value, { variable }
      assertIsArray value, { variable }
      value
    when "*"
      if value?
        assertIsArray value, { variable }
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
  parsed: parse template
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

decodeComponents = ( bindings, template, source ) ->
  for component, i in template
    if component.expression?
      bindings[ component.expression.variable ] = do ->
        switch component.expression.modifier
          when undefined, null
            assertIsDefined source[i], component.expression
            source[ i ]
          when "?"
            if source[ i ]?
              source[ i ]
          when "+"
            assertIsDefined source[i], component.expression
            source[ i..-1 ]
          when "*"
            if source[ i ]?
              source[ i..-1 ]

createDecodingContext = ( template, url ) ->
  parsed:
    template: parse template
    url: parse url
  result: {}

decodeOrigin = Fn.tee ( context ) ->
  { parsed, result } = context
  decodeComponents result, 
    parsed.template.origin.domain,
    parsed.url.origin.domain

decodePath = Fn.tee ( context ) ->
  { parsed, result } = context
  # TODO is there a possible error condition here?
  if parsed.template.path? && parsed.url.path?
    decodeComponents result, parsed.template.path, parsed.url.path

decodeQuery = Fn.tee ( context ) ->
  { parsed, result } = context
  # TODO is there a possible error condition here?
  if parsed.template.query? && parsed.url.query?
    for component, i in parsed.template.query
      { key, value } = component
      if value.expression?
        result[ value.expression.variable ] = do ->
          switch value.expression.modifier
            when undefined, null
              entry = parsed.url.query.find ( entry ) -> entry.key == key
              assertIsDefined entry, key
              entry.value
            when "?"
              if ( entry = parsed.url.query.find ( entry ) -> entry.key == key )?
                entry.value
            when "+"
              # TODO
              entries = parsed.url.query.filter ( entry ) -> entry.key == key
              if entries.length < 1
                throw failure "expected at least one", { key }
              entries.map ({ value }) -> value
            when "*"
              # TODO
              entries = parsed.url.query.filter ( entry ) -> entry.key == key
              entries.map ({ value }) -> value

decode = Fn.pipe [
  createDecodingContext
  decodeOrigin
  decodePath
  decodeQuery
  Obj.get "result"
]

export { encode, decode }
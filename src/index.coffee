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
    path
    Parse.optional query 
  ]
  Parse.merge
]

createEncodingContext = ( template, bindings ) ->
  parsed: parse template
  result: ""
  bindings: bindings

encodeText = Fn.curry Fn.rtee ( text, context ) ->
  context.result += text

encodeFrom = Fn.curry Fn.rtee ( getter, context ) ->
  context.result += getter context

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

encodeDomain = encodeFrom ({ parsed, bindings }) ->
  It.join ".",
    evaluateComponents parsed.origin.domain, bindings

encodeOrigin = Fn.pipe [
  encodeFrom ({ parsed }) -> parsed.origin.protocol
  encodeText "://"
  encodeDomain
]

encodePathComponents = encodeFrom ({ parsed, bindings }) ->
  It.join "/",
    evaluateComponents parsed.path, bindings

encodePath = Fn.pipe [
  encodeText "/"
  encodePathComponents
]

encodeQueryComponents = encodeFrom ({ parsed, bindings }) ->
  It.join "&",
    evaluateComponents parsed.query, bindings

encodeQuery = Fn.pipe [
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

createDecodingContext = ( template, url ) ->
  parsed:
    template: parse template
    url: parse url
  result: {}

decodeOrigin = Fn.tee ( context ) ->
  { parsed, result } = context
  for component, i in parsed.template.origin.domain
    if component.expression?
      result[ component.expression.variable ] = parsed.url.origin.domain[ i ]

decodePath = Fn.tee ( context ) ->
  { parsed, result } = context
  for component, i in parsed.template.path
    if component.expression
      result[ component.expression.variable ] = parsed.url.path[ i ]

decodeQuery = Fn.tee ( context ) ->
  { parsed, result } = context
  for component, i in parsed.template.query
    { key, value } = component
    if value.expression?
      result[ value.expression.variable ] = parsed.url.query[ i ].value

decode = Fn.pipe [
  createDecodingContext
  decodeOrigin
  decodePath
  decodeQuery
  Obj.get "result"
]

print = (value) -> console.log JSON.stringify value, null, 2

# print parse "https://acme.org/foo/bar?baz=123&buzz=456"

# print parse "https://{subdomain?}.acme.org/{foo*}?baz=123&{buzz}"

print encode "https://{subdomain?}.acme.org/{foo*}?baz=123&{buzz}",
  subdomain: "www"
  foo: [ "bar", "baz" ]
  buzz: "42"

print decode "https://{subdomain?}.acme.org/{foo*}?baz=123&{buzz}",
  "https://www.acme.org/bar/baz?baz=123&buzz=42"

# export { encode, decode }
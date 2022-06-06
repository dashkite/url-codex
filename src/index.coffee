import * as Parse from "@dashkite/parse"
import * as Fn from "@dashkite/joy/function"
import * as Type from "@dashkite/joy/type"
import * as Text from "@dashkite/joy/text"
import { generic } from "@dashkite/joy/generic"

protocol = Parse.pipe [
  Parse.text "https"
  Parse.tag "protocol"
]

scheme = Parse.pipe [
  Parse.all [ protocol, Parse.skip Parse.text ":" ]
  Parse.merge
]

domain = Parse.pipe [
  Parse.list ( Parse.text "." ), Parse.re /^[A-Za-z0-9\-]+/
  Parse.map Text.toLowerCase
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
      component
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
  Parse.list ( Parse.skip Parse.text "&" ), assignment
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

console.log parse "https://acme.org/foo/bar?baz=123&buzz=456"


# export { encode, decode }
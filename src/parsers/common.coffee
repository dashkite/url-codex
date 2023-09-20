import * as Parse from "@dashkite/parse"
import * as Text from "@dashkite/joy/text"

protocol = Parse.pipe [
  # Parse.text "https"
  Parse.re /^https|http|drn/
  Parse.tag "protocol"
]

scheme = Parse.pipe [
  Parse.all [ protocol, Parse.skip Parse.text ":" ]
  Parse.merge
]

name = Parse.pipe [
  Parse.re /^[A-Za-z0-9\-]+/
  Parse.map Text.toLowerCase
]

component = Parse.pipe [
  Parse.re /^[\w\-\.\~\%\!\$\&\'\(\)\*\+\,\;\=\:\@]+/
  Parse.map decodeURIComponent
]

symbol = Parse.re /^[\w\-]+/

value = Parse.pipe [
  Parse.re /^[\w\-\.\~\%\!\$\'\(\)\*\+\,\;\:\@\/\?]+/
  Parse.map decodeURIComponent
]

assignment = Parse.pipe [
  Parse.all [
    Parse.pipe [
      symbol
      Parse.tag "key"
    ]
    Parse.skip Parse.text "="
    Parse.pipe [
      value
      Parse.tag "value"
    ]
  ]
  Parse.merge
]

export {
  protocol
  scheme
  name
  component
  symbol
  value
  assignment
}
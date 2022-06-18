import * as Parse from "@dashkite/parse"
import {
  protocol
  scheme
  name
  component
  symbol
  assignment
} from "./common"


domain = Parse.pipe [
  Parse.list ( Parse.text "." ), name
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

path = Parse.pipe [
  Parse.all [
    Parse.skip Parse.text "/"
    Parse.optional Parse.list ( Parse.text "/" ), component
  ]
  Parse.flatten
  Parse.tag "path"
]

query = Parse.pipe [
  Parse.skip Parse.text "?"
  Parse.list ( Parse.skip Parse.text "&" ), assignment
  Parse.tag "query"
]

url = Parse.parser Parse.pipe [
  Parse.all [
    Parse.optional origin
    Parse.optional path
    Parse.optional query 
  ]
  Parse.merge
  Parse.verify "origin or path",
    ({ origin, path }) -> origin? || path?
]

export { url }
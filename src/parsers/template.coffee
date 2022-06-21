import * as Parse from "@dashkite/parse"
import {
  protocol
  scheme
  name
  component
  symbol
  assignment
} from "./common"

variable = Parse.pipe [
  symbol
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

expression = ( type ) ->
  Parse.pipe [
    Parse.between [ ( Parse.text "{" ), ( Parse.text "}") ],
      Parse.pipe [
        Parse.all [
          variable
          Parse.optional modifier
        ]
        Parse.merge
        Parse.map ( expression ) -> { expression..., type }
      ]
    Parse.tag "expression"
  ]

domain = Parse.pipe [
  Parse.list ( Parse.text "." ), Parse.any [
    expression "domain"
    name
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

path = Parse.pipe [
  Parse.all [
    Parse.skip Parse.text "/"
    Parse.optional Parse.list ( Parse.text "/" ), 
      Parse.any [
        expression "path"
        component
      ]
  ]
  Parse.flatten
  Parse.tag "path"
]


query = Parse.pipe [
  Parse.skip Parse.text "?"
  Parse.list ( Parse.skip Parse.text "&" ),
    Parse.any [ 
      Parse.pipe [
        expression "query"
        Parse.map ({ expression }) ->
          key: expression.variable
          value: { expression }
      ]
      assignment 
    ]
  Parse.tag "query"
]

template = Parse.parser Parse.pipe [
  Parse.all [
    Parse.optional origin
    Parse.optional path
    Parse.optional query 
  ]
  Parse.merge
  Parse.verify "origin or path",
    ({ origin, path }) -> origin? || path?
]

export { template }
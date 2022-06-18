import * as Fn from "@dashkite/joy/function"
import * as Obj from "@dashkite/joy/object"
import * as Text from "@dashkite/joy/text"
import * as It from "@dashkite/joy/iterable"

import {
  literals
  variables
} from "./helpers"

parts = []

parts.push
  generate: (name) ->
    name = literals[ name ]
    name: "literal"
    text: name
    tests:
      parse:
        path: name
  place: "any"

parts.push
  generate: (name) ->
    name = variables[ name ] + "p"
    name: "expression"
    text: "{#{name}}"
    tests:
      parse:
        path:
          expression:
            variable: name
  place: "any"

for modifier in [ "?", "*", "+" ]
  do (modifier) ->
    parts.push
      generate: (name) ->
        name = variables[ name ] + "p"
        name: "expression #{modifier}"
        text: "{#{name}#{modifier}}"
        tests:
          parse:
            path:
              expression:
                variable: name
                modifier: modifier

      place: "end"

getName = Fn.pipe [
  It.map Obj.get "name"
  It.join " / "
]

getTemplate = Fn.pipe [
  It.map Obj.get "text"
  It.join "/"
  (path) -> "/#{path}"
]

getTests = Fn.pipe [
  It.map Fn.pipe [
    Obj.get "tests"
    Obj.get "parse"
    Obj.get "path"
  ]
  (components) -> parse: path: components
]

getPathTest = (list) ->
  name: getName list
  template: getTemplate list
  tests: getTests list

cases = []

for A in parts when A.place == "any"
  a = A.generate "A"
  cases.push getPathTest [ a ]

  for B in parts when B.place == "any"
    b = B.generate "B"
    cases.push getPathTest [ a, b ]

    for C in parts when C.place == "end"
      c = C.generate "C"
      cases.push getPathTest [ a, b, c ]

export { cases }
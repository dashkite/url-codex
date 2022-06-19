import * as Parse from "@dashkite/parse"
import * as Fn from "@dashkite/joy/function"

# Protocol parser helpers

# presently, the protocol can't be templatized
# so this is basically the same as parsing a URL

Protocol =
  visitor: ( bindings ) ->
    ( protocol ) ->
      Parse.all [
        Parse.skip Parse.text protocol
        Parse.skip Parse.text "://"
      ]

export { Protocol }
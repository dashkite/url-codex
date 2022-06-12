import * as Parse from "@dashkite/parse"
import * as Fn from "@dashkite/joy/function"

import {
  suffix
} from "./helpers"

# Protocol parser helpers

# presently, the protocol can't be templatized
# so this is basically the same as parsing a URL

Protocol =
  visitor: ( bindings ) ->
    Fn.pipe [
        Parse.text
        suffix Parse.text "://"
      ]

export { Protocol }
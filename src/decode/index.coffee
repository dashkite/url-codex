import * as Parse from "@dashkite/parse"
import * as Fn from "@dashkite/joy/function"

import * as Parsers from "../parsers"
import { traverse } from "../traverse"

import { Protocol } from "./protocol"
import * as Domain from "./domain"
import * as Path from "./path"
import * as Query from "./query"

push = Fn.curry ( px, p ) -> px.push p

decode = Fn.curry ( template, url ) ->

  # we're going to return bindings
  bindings = {}

  # to do that, we first build up an array of
  # parser functions, which we'll combine later
  # to build the parser
  patterns = []  

  # we now traverse the template's parse tree
  # building up our list of parsers as we go
  tree = Parsers.template template

  traverse tree,
    protocol: Fn.pipe [
      Protocol.visitor bindings
      push patterns
    ]
    domain: Fn.pipe [
      Domain.visitor bindings
      push patterns
    ]
    path:  Fn.pipe [
      Path.visitor bindings
      push patterns
    ]
    query: Fn.pipe [
      Query.visitor bindings
      push patterns
    ]

  # okay, we now have a list of parsers, each corresponding
  # to part of the URL (origin, path, query). we combine those
  # and then process the resulting bindings.
  parse = Parse.parser Parse.pipe [
    Parse.all patterns
    Parse.flatten
    Parse.merge
    Parse.map ( results ) -> { bindings..., results... }
  ]

  # we can now parse the URL--
  parse url

  # finally, we have the bindings, which we return
  # bindings

# match is just decode but we ignore parsing errors
match = Fn.curry ( template, url ) ->
  try
    decode template, url
  catch error
    if ( error.message.startsWith "parse error" )
      undefined
    else
      throw error

export { decode, match }
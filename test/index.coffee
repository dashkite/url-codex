import assert from "@dashkite/assert"
import { test, success } from "@dashkite/amen"
import print from "@dashkite/amen-console"

import { encode, decode, match } from "../src"
import * as Parsers from "../src/parsers"

import * as Path from "./path"


do ->

  print await test "@dashkite/url-codex", [

    test "parse templates", [

      test "paths", do ->

        for { name, template, tests } in Path.cases 
          test template, ->
            assert.deepEqual tests.parse, Parsers.template template

      ]
    
  ]

#     test "url parser", [

#       test "success", do ->
#         for { name, type, url, expect } in scenarios[ "url" ][ "success" ]
#           test ( name ? url ), ->
#             console.log Parsers.url url
#             assert.deepEqual expect, Parsers.url url

#       test "failure", do ->
#         for { name, type, url, expect } in scenarios[ "url" ][ "failure" ]
#           test ( name ? url ), ->
#             assert.throws -> Parsers.url url

#     ]
    
#     test "template parser", [

#       # we should be able to parse URLs as template
#       # that have no variables...
#       test "no variables", [
        
#         test "success", do ->
#           for { name, type, url, expect } in scenarios[ "url" ][ "success" ]
#             test ( name ? url ), ->
#               assert.deepEqual expect, Parsers.template url

#         test "failure", do ->
#           for { name, type, url, expect } in scenarios[ "url" ][ "failure" ]
#             test ( name ? url ), ->
#               assert.throws -> Parsers.template url
#       ]

#       test "with variables", [

#         test "success", do ->
#           for { name, type, template, expect } in scenarios[ "template" ][ "success" ]
#             test ( name ? template ), ->
#               assert.deepEqual expect, Parsers.template template

#         test "failure", do ->
#           for { name, type, template, expect } in scenarios[ "template" ][ "failure" ]
#             test ( name ? template ), ->
#               assert.throws -> Parsers.template template
      
#       ]

#     ]

#     test "encode / decode", do ->

#       for { name, template, url, bindings } in scenarios[ "encode/decode" ]
#         test ( name ? template ), ->
#           assert.equal url, encode template, bindings
#           assert.deepEqual bindings, decode template, url

#     test "encode", [

#       test "failure", do ->
#         for { name, template, bindings } in scenarios[ "encode" ][ "failure" ]
#           test ( name ? template ), ->
#             assert.throws -> encode template, bindings

#     ]

#     test "decode", [

#       test "failure", do ->

#         for { name, template, url } in scenarios[ "decode" ][ "failure" ]
#           test ( name ? template ), ->
#             assert.throws -> decode template, url


#     ]

#     test "match", [

#       test "success", do ->
#         for { name, template, url, bindings } in scenarios[ "encode/decode" ]
#           test ( name ? template ), ->
#             assert ( _bindings = match template, url )?
#             assert.deepEqual _bindings, bindings

#       test "failure", do ->
#         for { name, template, url } in scenarios[ "decode" ][ "failure" ]
#           test ( name ? template ), ->
#             assert !(match template, url)

#     ]
#   ]

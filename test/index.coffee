import assert from "@dashkite/assert"
import { test, success } from "@dashkite/amen"
import print from "@dashkite/amen-console"

import { encode, decode, match } from "../src"
import scenarios from "./scenarios"

do ->

  print await test "@dashkite/url-codex", [

    test "url parser"

    test "template parser"

    test "encode / decode", do ->
      for { name, template, url, bindings } in scenarios[ "encode/decode" ]
        test ( name ? template ), ->
          assert.equal url, encode template, bindings
          assert.deepEqual bindings, decode template, url

    test "match", [

      test "success", do ->
        for { name, template, url, bindings } in scenarios[ "encode/decode" ]
          test ( name ? template ), ->
            assert ( _bindings = match template, url )?
            assert.deepEqual _bindings, bindings

      test "failure", do ->
        for { name, template, url } in scenarios[ "match failure" ]
          test ( name ? template ), ->
            assert !(match template, url)

    ]
  ]

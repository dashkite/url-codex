import assert from "@dashkite/assert"
import { test, success } from "@dashkite/amen"
import print from "@dashkite/amen-console"

import { encode, decode, match } from "../src"
import * as Parsers from "../src/parsers"
import scenarios from "./scenarios"

do ->

  print await test "@dashkite/url-codex", [

    test "url parser", do ->
      for { name, url, expect } in scenarios[ "url" ]
        test ( name ? url ), ->
          assert.deepEqual expect, Parsers.url url

    test "template parser", [

      # we should be able to parse URLs as template
      # that have no variables...
      test "no variables", do ->
        for { name, url, expect } in scenarios[ "url" ]
          test ( name ? url ), ->
            assert.deepEqual expect, Parsers.template url

      test "with variables", do ->
        for { name, template, expect } in scenarios[ "template" ]
          test ( name ? template ), ->
            assert.deepEqual expect, Parsers.template template

    ]

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

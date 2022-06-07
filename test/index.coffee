import assert from "@dashkite/assert"
import { test, success } from "@dashkite/amen"
import print from "@dashkite/amen-console"

import { encode, decode } from "../src"
import scenarios from "./scenarios"

do ->
  print await test "@dashkite/url-codex", do ->
    for { name, template, data, expect } in scenarios
      test ( name ? template ), ->
        assert.equal expect, encode template, data
        assert.deepEqual data, decode template, expect

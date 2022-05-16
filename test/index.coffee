import assert from "@dashkite/assert"
import { test, success } from "@dashkite/amen"
import print from "@dashkite/amen-console"

import { expand } from "../src"
import scenarios from "./scenarios"
import expected from "./expected"
import data from "./data"

do ->
  print await test "@dashkite/polaris", ->
    actual = expand scenarios, data
    assert.deepEqual actual, expected
    

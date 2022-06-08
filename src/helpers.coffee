import * as Fn from "@dashkite/joy/function"
import * as Type from "@dashkite/joy/type"
import { Messages } from "@dashkite/messages"
import failures from "./failures"
import * as Parsers from "./parsers"

messages = Messages.create()
messages.add failures
messages.prefix = "url-codex"

failure = ( code, context ) ->
  messages.failure code, context

assert = Fn.curry ( predicate, code, value, context ) ->
  if ! predicate value
    throw failure code, context

assert.isDefined = assert Type.isDefined, "missing variable"
assert.isString = assert Type.isString, "expecting string"
assert.isArray = assert Type.isArray, "expecting array"


export {
  messages
  failure
  assert
}
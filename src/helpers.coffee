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

hasNoModifier = ({ modifier }) -> !modifier?
hasOptionalModifier = ({ modifier }) -> modifier == "?" 
hasWildcardModifier = ({ modifier }) -> modifier == "*"
hasPlusModifier = ({ modifier }) -> modifier == "+"

export {
  messages
  failure
  hasNoModifier
  hasOptionalModifier
  hasWildcardModifier
  hasPlusModifier
}
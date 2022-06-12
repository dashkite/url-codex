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

# TODO we really need to add this to Joy
flatten = ([ head, rest... ]) ->
  if rest.length > 0
    if Type.isArray head
      [ ( flatten head )..., ( flatten rest )... ]
    else
      [ head, ( flatten rest )... ]
  else if Type.isArray head
    flatten head
  else if head?
    [ head ]
  else []

hasNoModifier = ({ modifier }) -> !modifier?
hasOptionalModifier = ({ modifier }) -> modifier == "?" 
hasWildcardModifier = ({ modifier }) -> modifier == "*"
hasPlusModifier = ({ modifier }) -> modifier == "+"

export {
  messages
  failure
  flatten
  hasNoModifier
  hasOptionalModifier
  hasWildcardModifier
  hasPlusModifier
}
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
flatten = ( it ) ->
  result = []
  for x from it
    if Type.isArray x
      result = [ result..., x... ]
    else
      result = [ result..., x ]
  result


export {
  messages
  failure
  flatten
}
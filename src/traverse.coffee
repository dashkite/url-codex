import * as Fn from "@dashkite/joy/function"
import * as Type from "@dashkite/joy/type"
import * as Val from "@dashkite/joy/value"
import * as It from "@dashkite/joy/iterable"

# TODO we really need to add this to Joy
flatten = ( it ) ->
  result = []
  for x from it
    if Type.isArray x
      result = [ result..., x... ]
    else
      result = [ result..., x ]
  result

traverse = (tree, handlers) ->

  resolved = Val.clone tree
  resolve = ( item ) ->
    if item.expression?
      handlers.expression item.expression
    else
      item

  if handlers.expression?
    if tree.origin?.domain?
      resolved.origin.domain = do Fn.pipe [
        -> tree.origin.domain
        It.map resolve
        It.select Type.isDefined
        flatten
      ]

    if tree.path?
      resolved.path = do Fn.pipe [
        -> tree.path
        It.map resolve
        It.select Type.isDefined
        flatten
      ]

    if tree.query?
      resolved.query = do Fn.pipe [
        -> tree.query
        It.map ({ key, value }) ->
          { key, value: resolve value }
        It.select ({ key, value }) -> value?
        It.map ({ key, value }) ->
          if Type.isArray value
            for _value in value
              { key, value: _value }
          else
            { key, value }
        flatten
      ]

  if resolved.origin?.protocol?
    handlers.protocol? resolved.origin.protocol
  else
    handlers.missing?.protocol?()

  if resolved.origin?.domain? && ! Val.isEmpty resolved.origin?.domain
    handlers.domain? resolved.origin.domain 
  else
    handlers.missing?.domain?()

  if resolved.path? && ! Val.isEmpty resolved.path
    handlers.path? resolved.path 
  else
    handlers.missing?.path?()

  if resolved.query && ! Val.isEmpty resolved.query
    handlers.query? resolved.query 
  else
    handlers.missing?.query?()

export { traverse }
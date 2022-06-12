import * as Parse from "@dashkite/parse"
import * as Fn from "@dashkite/joy/function"
import * as Type from "@dashkite/joy/type"

prefix = Fn.curry ( p, q ) -> Parse.all [ p, q ]
suffix = Fn.curry ( s, p ) -> Parse.all [ p, s ]
push = Fn.curry ( px, p ) -> px.push p

# We can't know until we've processed the template whether
# or not a given part of the URL is required. We keep track
# of this with a state object. If we find that it's optional,
# ex: it uses a ? modifier, we modify the parse function.
optional = Fn.curry ( state, p ) ->
  if state.optional then Parse.optional p else p


# Map an value or expression to a handler.
# Given a set of extraction handlers, determine which
# one to call based on whether the value provided
# is an expression and, if so, which modifier is specified.

extract = build = Fn.curry ( handlers, value ) ->
  if value.key?
    { key, value } = value
  if value.expression?
    handler = handlers[ value.expression.modifier ] ? handlers.default
    handler value.expression.variable
  else if key?
    handler { key, value }
  else
    handlers.literal? value

# Once we have a set of results, in the form of objects with
# a single property (we can't use assoc pairs because we need
# to flatten them since we don't know where in the parse tree
# they originate), we want to update the bindings object
# accordingly. If the corresponding binding is an array,
# that means we #parsed a list expression (+ or *), so we want
# to assign the result as an away. If the association value 
# itself is an array, that means we parsed it as a list,
# so we want to concatenate it. For query assignments, we
# never get an array, so we also want to handle just pushing
# an association onto the binding array.

save = Fn.curry ( bindings, results ) ->
  if Type.isArray results
    for result in results when Type.isObject result
      for key, value of result
        if Type.isArray bindings[ key ]
          if Type.isArray value
            bindings[ key ] = [ bindings[ key ]..., value... ]
          else
            bindings[ key ].push value
        else
          bindings[ key ] = value

export {
  prefix
  suffix
  push
  extract
  build
  save
  optional
}
# Map an value or expression to a handler.
# Given a set of extraction handlers, determine which
# one to call based on whether the value provided
# is an expression and, if so, which modifier is specified.

evaluate = ( handlers ) ->
  ( value ) ->
    if value.key?
      { key, value } = value
    if value.expression?
      handler = handlers[ value.expression.modifier ] ? handlers.default
      handler value.expression.variable
    else if key?
      handler { key, value }
    else
      handlers.literal? value

export {
  evaluate
}
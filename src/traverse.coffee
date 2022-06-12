traverse = (tree, handlers) ->

  if handlers.expression?
    if tree.origin.domain?
      for { expression }, i in tree.origin.domain when expression?
        tree.origin.domain[ i ] = handlers.expression expression

    if tree.path?
      for { expression }, i in tree.path when expression?
        tree.path[ i ] = handlers.expression expression

    if tree.query?
      for { value }, i in tree.query when value.expression?
        tree.query[ i ].value = handlers.expression value.expression

  handlers.protocol? tree.origin.protocol if tree.origin.protocol?
  handlers.domain? tree.origin.domain if tree.origin.domain?
  handlers.path? tree.path if tree.path?
  handlers.query? tree.query if tree.query?

export { traverse }
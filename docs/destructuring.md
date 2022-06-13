The current implementation does not handle expressions that follow optional or wildcard expressions. Ex:

```
/{foo*}/{bar}
```

This works fine for encoding, but for decoding, the expression `foo*` consumes the entire path, leaving nothing for `bar`.

The solution to this is for `{foo*}` to know that there is another expression that still needs to be parsed. We can do this by keep tracking as we build the parser. A partial implementation of this is in the `destructure` branch.

We’ll call this counter the _leave counter_. When we build the parser, we include an `assign` combinator to place the leave counter into the parser state. When we successfully parse an expression that incremented the counter, we decrement it accordingly. For example, in the example above, the `bar` expression would increment the counter when building the parser. Once we parsed the expression, we’d decrement it.

Next, we add a new primitive that pushes the current parser state as a property of the state data so that we can backtrack to prior states. We also introduce a new list parser that always pushes the state as it parses a list, so that we can backtrack as much as necessary to leave additional list items for the ensuing expressions. Finally, we introduce another operation that handles the backtracking itself.

This basically works except that there’s also an outer list. That is, we join the expressions, like so:

```coffeescript
    Parse.join Parse.text "/"
```

When we backtrack, we end up past the `/` character because the expression doesn’t know about the join. For example, consider this template:

```
/{foo?}/bar
```

and the expression:

```
/bar
```

The leave counter is set to one (for the `bar` literal). We parse `foo?` and get a match. However, since the leave counter is one, we put back the match. The input is now `bar`. However, the `join` combinator is looking for `/` as the delimiter before the next expression.

We can probably solve this by implementing a version of join that handles state selection. The objection to this (and to the special list combinator) is that we’d rather this be more flexible, using simple combinators that can be remixed in lots of different ways. For example, rather than push the state within a specialized list or join combinator, we can simply do this for each list item or delimiter, depending on what we want to do.

That is, what we’ve uncovered is the need for the ability to maintain a stack of parser states to allow dynamic selection of state. We also need to be able to increment and decrement counters. This seems like it should be sufficient to support destructuring with trailing expressions, but it’s not entirely clear. However, since we don’t actually _need_ this capability just now, we’ll defer that until later.
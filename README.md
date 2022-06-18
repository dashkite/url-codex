# URL Codex

_URL interpolation and destructuring_

```coffeescript
import { encode, decode } from "@dashkite/url-codex"

data = name: alice

greeting = encode "https://acme.org/greeting/{name}", data

assert greeting == "https://acme.org/greeting/alice"

result = decode "https://acme.org/greeting/{name}",
  "https://acme.org/greeting/alice"

assert.deepEqual result, data

```

- Inspired by (but not compliant with) RFC 6570
- Wildcard and optional parameters
- Query parameters

# Usage

URL templates should be formatted just like ordinary URLs, except that you may include expressions inside curly braces, like so: `{foo}`. 

Expressions may have a modifier: 

- `?` means the expression is optional
- `*` means it may match zero or more items, 
- `+` means it may match one or more items

No modifier means the expression matches exactly one item.

The match depends on where in the URL the expression is placed:

- within the origin, an item is a domain label
- within the path, an item is a path component
- within the query, an item is a key-value pair

When encoding, all path and query items are URL encoding. When decoded, all path and query items are URL decoded.

A template must specify at least an origin or path.

## Valid Templates

```
/foo
/{foo}
/{foo?}
/{foo*}?{bar}
https://acme.org?{bar+}
https://acme.org/foo?{bar+}&{baz}
```


## Invalid Templates

Valid templates per 6570 are often invalid using URL Codex.

```
# 6570          # url codex
{/foo*}         # /{foo*}
/foo{?bar,baz}  # /?{bar}&{baz}
```

# Limitations

## Wildcard Expressions

Currently, wildcard expressions (using `+` or `*` modifiers) must be the last expression in a given section of a URL. This is because they will match against all the remain items in that section.

For example, the following expression will fail to decode correctly:

```
/{foo*}/bar
```

Given the following URL:

```
/f/o/o/bar
```

this will first assign `foo` to `[ "f", "o", "o", "bar" ]` and then fail to parse the trailing literal `bar`.

Encoding works. See #1 for more information.


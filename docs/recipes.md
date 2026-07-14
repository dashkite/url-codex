# Recipes

This document provides usage guides and common recipes for URL Codex.

## Interpolating data into a URL

URL Codex enables developers to construct dynamic URLs from data objects. You provide a template string and the data to bind.

```coffeescript
import { encode } from "@dashkite/url-codex"

data = 
  name: "alice"
  greeting: "hello"

url = encode "https://acme.org/{greeting}/{name}", data
# url is "https://acme.org/hello/alice"
```

## Destructuring a URL into data

Developers can reverse the process, extracting data from a URL using a template. This allows creators to parse inbound requests easily.

```coffeescript
import { decode } from "@dashkite/url-codex"

result = decode "https://acme.org/{greeting}/{name}", "https://acme.org/hello/alice"
# result is { greeting: "hello", name: "alice" }
```

## Adding Query Parameters

To include query parameters, use `?` followed by `{variable_name}` where `variable_name` maps to an object containing query keys and values.

```coffeescript
import { encode } from "@dashkite/url-codex"

data = 
  path: "search"
  query:
    q: "url codex"
    page: 1

url = encode "https://acme.org/{path}?{query}", data
# url is "https://acme.org/search?q=url%20codex&page=1"
```

## Advanced: Using Optional Parameters

URL Codex supports optional parameters using the `?` modifier. If the variable is absent or `null`, the segment is omitted.

```coffeescript
import { encode, decode } from "@dashkite/url-codex"

# Encoding an optional path segment
url = encode "https://acme.org/{user}/{status?}", { user: "alice", status: null }
# url is "https://acme.org/alice"

# Decoding a missing optional query parameter
result = decode "https://acme.org/search?{q?}", "https://acme.org/search"
# result is { q: undefined }
```

## Advanced: Destructuring Wildcard Paths

Using the `*` or `+` modifiers, developers can capture or interpolate an arbitrary number of path segments into an array.

```coffeescript
import { encode, decode } from "@dashkite/url-codex"

# Encoding a wildcard path array
url = encode "https://acme.org/{path*}", { path: [ "components", "button", "v1" ] }
# url is "https://acme.org/components/button/v1"

# Decoding a wildcard path into an array
result = decode "https://acme.org/{path+}", "https://acme.org/src/lib/index.js"
# result is { path: [ "src", "lib", "index.js" ] }
```

## Advanced: Dynamic Query Parameter Objects

Wildcard modifiers (`*` and `+`) also apply to query strings, allowing creators to map all query parameters into a single object.

```coffeescript
import { encode, decode } from "@dashkite/url-codex"

# Encoding a wildcard query object
url = encode "https://acme.org/search?{options*}", { options: { sort: "asc", limit: 10 } }
# url is "https://acme.org/search?sort=asc&limit=10"

# Decoding arbitrary query parameters into an object
result = decode "https://acme.org/api?{params*}", "https://acme.org/api?foo=bar&baz=123"
# result is { params: { foo: "bar", baz: "123" } }
```

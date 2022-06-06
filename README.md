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



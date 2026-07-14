# URL Codex

*URL interpolation and destructuring*

[![Hippocratic License HL3-CORE](https://img.shields.io/static/v1?label=Hippocratic%20License&message=HL3-CORE&labelColor=5e2751&color=bc8c3d)](https://firstdonoharm.dev/version/3/0/core.html)

URL Codex provides simple JSON Query-based text interpolation and destructuring for JavaScript.

## Features

- Interpolates variables directly into URLs
- Destructures URLs into variables
- Inspired by (but not compliant with) RFC 6570
- Support for wildcard and optional parameters
- Support for query parameters

## Installation

```shell
pnpm install @dashkite/url-codex
```

## Usage

```coffeescript
import { encode, decode } from "@dashkite/url-codex"

data = name: "alice"

greeting = encode "https://acme.org/greeting/{name}", data

assert greeting == "https://acme.org/greeting/alice"

result = decode "https://acme.org/greeting/{name}",
  "https://acme.org/greeting/alice"

assert.deepEqual result, data
```

## Other Resources

- [Recipes](docs/recipes.md)
- [Reference](docs/reference.md)
- [Technical Notes](docs/technical-notes.md)
- [Testing](docs/testing.md)

# Reference

This document details the public API for URL Codex.

## encode

$encode: (template, bindings) \rightarrow string$

Encodes an object into a URL using the provided template.

- `template`: The URL string containing variables in curly braces `{}`.
- `bindings`: An object containing the data to inject into the template.

## decode

$decode: (template, url) \rightarrow object$

Decodes a URL string into an object using the provided template.

- `template`: The URL string containing variables in curly braces `{}`.
- `url`: The URL string to destructure.

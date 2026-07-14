# Technical Notes

This document captures underlying design decisions and technical considerations for URL Codex.

### Prioritizing Reversability

RFC 6570 and the URL Pattern API are both efforts to standardize in this space, and we draw much inspiration from them. However, neither of these dedicate effort to the reversability of the transformation. URL Codex takes the same spirit as Open Web standards, but we prioritize reversability. 

It's part of a concept tied to the importance of URLs as very flexible *universal* locators. This library is an attempt to acknowledge that power while supporting an expression in different forms. As a stringified URL, it's excellent as a wire format. But programmatically, the structure decoded by URL Codex is much more amenable to programmatic manipulation.

### Joy Library Integration

URL Codex leverages the Joy library for functional composition and type checking. By utilizing Joy's functional abstractions, such as `Fn.pipe`, `Fn.curry`, and `It.map`, the codebase maintains a highly declarative and composable structure.

### Supported Template Formats

URL Codex uses a custom parser for its templates, inspired by RFC 6570 but favoring simplicity over strict compliance. The variables within templates define expected structural bindings (e.g., path segments, domains, query parameters), enabling robust two-way transformations.

### Recursive Descent Parsing

URL Codex is built using recursive descent parsing, a powerful technique that DashKite makes repeated use of across its projects. This approach is made expressive, powerful, and complete by utilizing the `@dashkite/parse` library.

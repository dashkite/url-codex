# Polaris

_Simple JSON Query-based text interpolation for JavaScript_

```coffeescript
import { expand } from "@dashkite/polaris"

data = name: Alice

greeting = expand "Hello, ${ name }", data

assert greeting == "Hello, Alice"
```

- JSON query expressions
- Escaping using `\`
- Recursive expanson of objects and arrays



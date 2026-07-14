# Testing

This document outlines the testing strategy for URL Codex.

## Running Tests

URL Codex utilizes the Amen testing framework. Tests focus on verifying the correctness of the parser, encoders, and decoders against various edge cases.

To execute the test suite, run the following command:

```shell
npx genie test
```

## Testing Approach

The tests cover both interpolation (`encode`) and destructuring (`decode`) to ensure parity between the two operations. Key areas of focus include:

- Wildcard parsing
- Query string serialization and parsing
- Missing variable handling

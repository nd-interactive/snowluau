# Remove Types

Removes type aliases, type functions, local and function annotations, generic
parameters, type assertions, and explicit generic instantiations.

Nested expressions are transformed in the same pass. Line endings are preserved,
and separators are retained where removing types could join tokens or statements.
Assertions on calls and varargs keep parentheses so they still produce one value.

## Example

```luau
export type Wow = "moM"

local hello: any = 123 :: number

```

into

```luau


local hello = 123
```

## Options

This transformer has no options.

## Tests

Run the regression tests with the Lute version pinned in `rokit.toml`:

```bash
rokit install
lute run tests/remove_types.luau
```

The tests reparse and compile each result, check that all type syntax is removed,
and compare its return values with the original code.

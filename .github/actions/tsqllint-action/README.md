# TSQLLint Github Action

This action runs the latest [TSQLLint](https://github.com/tsqllint/tsqllint).

## Inputs

### `path`

**Required** - Space separated path(s) to run linter against.
Wildcards can be specified using `*`.
Default is all SQL files.

### `config`

**Required** - Path to a [configuration file](https://github.com/tsqllint/tsqllint#configuration)
for the linter.

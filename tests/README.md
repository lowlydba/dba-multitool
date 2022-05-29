# Tests

Unit tests via [tSQLt](https://tsqlt.org/) and Pester,
code coverage by
[SQLCover](https://github.com/GoEddie/SQLCover) and
linting by [TSQLLint](https://github.com/tsqllint/tsqllint)
and [super-linter](https://github.com/github/super-linter).

## How it works

### tSQLt unit tests

Each stored procedure has all of its tSQLt unit tests stored in a single sql script in the `\tests\` folder and
uses the naming convention of `sp_name.Tests.sql`. These should mostly adhere to the following naming conventions:

- `[sp_name].[test sp fails ...]`
- `[sp_name].[test sp succeeds ...]`

### Pester tests

All of a stored proc's unit tests are run by a single corresponding Pester script, similarly
named `sp_name.Tests.ps1`, which:

- Installs the corresponding stored procedure's tSQLt tests
- Runs all unit tests for the stored procedure as a single Pester invocation

# Tests

Unit tests via [tSQLt](https://tsqlt.org/), code coverage by
[SQLCover](https://github.com/GoEddie/SQLCover), code coverage
tracking by [codecov.io](https://codecov.io/), and
linting by [TSQLLint](https://github.com/tsqllint/tsqllint).

## How to run

### Prequisites

A modern SQL Server instance version locally installed and a tSQLt database.

### Steps

Supply your development instance and the database where tSQLt has been preinstalled.
Windows Authentication is assumed.

Run the following PowerShell from the project root:

```powershell
.\tests\run\localdev_test.ps1 -SqlInstance "localhost" -Database "tSQLt"
```

This will:

* Install and run TSQLLint
* Build and run tSQLt unit tests
* Produce an html code coverage report on completion in a popup browser

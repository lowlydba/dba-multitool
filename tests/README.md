# Tests

Unit tests via [tSQLt](https://tsqlt.org/) and Pester,
code coverage by
[SQLCover](https://github.com/GoEddie/SQLCover) and
[codecov.io](https://codecov.io/), and
linting by [TSQLLint](https://github.com/tsqllint/tsqllint).

## How to run

### Prequisites

A modern SQL Server instance version locally installed and a tSQLt database.

### Steps

Supply your development instance and the database where tSQLt has been preinstalled.
Windows Authentication is assumed.

Temporarily update `tests\constants.ps1` with any values
specific to your local environment (Instance and Database)

Run the following PowerShell from the project root:

```powershell
.\tests\localdev_test.ps1
```

This will:

* Install all dependencies except a tSQLt database
* Build and run tSQLt unit tests via Pester
* Produce an html code coverage report on completion in a popup browser

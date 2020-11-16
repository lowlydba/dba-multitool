# Tests

Unit tests via [tSQLt](https://tsqlt.org/) and Pester,
code coverage by
[SQLCover](https://github.com/GoEddie/SQLCover) and
[codecov.io](https://codecov.io/), and
linting by [TSQLLint](https://github.com/tsqllint/tsqllint).

## How to run

### Prequisites

The following prereqs are *not* handled by the setup script:

* SQL Server 2012+ or equivalent
* tSQLt installed on a database (install scripts located in `tests\tSQLt\` if needed)

### Steps

1. Temporarily update `tests\constants.ps1` with any values
specific to your local environment (Instance and Database)

2. Run the following PowerShell from the project root:

```powershell
.\tests\localdev_test.ps1
```

This will:

* Install all dependencies (except a tSQLt database)
* Build and run tSQLt unit tests via Pester
* Produce an html code coverage report on completion in a popup browser

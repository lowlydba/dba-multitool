# Tests

Unit tests via [tSQLt](https://tsqlt.org/) and Pester run on Appveyor,
code coverage by
[SQLCover](https://github.com/GoEddie/SQLCover) and
[codecov.io](https://codecov.io/), and
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

- Installs the DBA MultiTool scripts
- Installs the corresponding stored procedure's tSQLt tests
- Runs all unit tests for the stored procedure as a single Pester invocation

This avoids having to hard-code or do messy querying to get each individual Pester test for a stored procedure
at the expense of obfuscating more detailed output (i.e. one failed test among 20 counts as a full falure in Appveyor). 

The output is printed in each [Appveyor](https://ci.appveyor.com/project/LowlyDBA/dba-multitool) job if a failure needs to be inspected.

### Appveyor

Each Pester test is then run against each configuration defined in `\appveyor\appveyor.yml` in order
to test against all supported SQL Server versions. These are auto-triggered for each commit made in a pull request.

## How to run

### Prequisites

The following prereqs are *not* handled by the setup script:

* SQL Server 2012+ or equivalent
* tSQLt installed on a database (run `appveyor\install_tsqlt.ps1` manually)

### Steps

1. Temporarily update `tests\constants.ps1` with any values
specific to your local environment (Instance and Database)

2. Run the following PowerShell from the project root `tests\localdev_test.ps1`

This will:

* Install all dependencies (except a tSQLt database)
* Produce an html code coverage report on completion in a popup browser

To skip the automated setup of dependencies, use the flag `-SkipSetup` when running the script.

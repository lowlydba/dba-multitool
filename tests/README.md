# Tests

Unit tests via [tSQLt](https://tsqlt.org/), code coverage by
[SQLCover](https://github.com/GoEddie/SQLCover), code coverage
tracking by [codecov.io](https://codecov.io/).

## How to run

Supply your development instance and the local database where tSQLt has been preinstalled. Windows Authentication is assumed.

Run from the project root:

```powershell
.\tests\run\localdev_test.ps1 -SqlInstance "localhost" -Database "tSQLt"
```

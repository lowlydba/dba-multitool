# sp_helpme

![License](https://img.shields.io/github/license/LowlyDBA/ExpressSQL?color=blue)
![SQL Server](https://img.shields.io/badge/SQL%20Server-2012--2019-red?logo=microsoft-sql-server)
[![Build status](https://ci.appveyor.com/api/projects/status/bak6km5grc3j63s8?svg=true)](https://ci.appveyor.com/project/LowlyDBA/expresssql)
![GitHub Workflow Status (branch)](https://img.shields.io/github/workflow/status/LowlyDBA/ExpressSQL/Lint%20Code%20Base/master?label=lint%20code%20master)
[![codecov](https://codecov.io/gh/LowlyDBA/ExpressSQL/branch/master/graph/badge.svg)](https://codecov.io/gh/LowlyDBA/ExpressSQL)

* [Purpose](#Purpose)
* [Usage](#Usage)
* [Contributing](#Contributing)
* [More](#More)

## Purpose

An drop-in modern alternative to sp_help.

Changes from the original include:

* Preferring printed messages over empty result sets for non-applicable data
* Including extended properties wherever possible
* Including create, modify, and more metadata about objects
* Referenced views are returned in two-part naming convention

## Usage

Basic example:

```tsql
EXEC sp_helpme 'dbo.Sales';
```

## Contributing

Missing a feature? Found a bug? Open an [issue][issue] to get some :heart:.

## More

Check out the other scripts in the [Express SQL Suite][express].

[express]: https://expresssql.lowlydba.com/
[issue]: https://github.com/LowlyDBA/ExpressSQL/issues

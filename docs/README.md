# Express SQL

![License](https://img.shields.io/github/license/LowlyDBA/ExpressSQL?color=blue)
![SQL Server](https://img.shields.io/badge/SQL%20Server-2012--2019-red?logo=microsoft-sql-server)
[![Build status](https://ci.appveyor.com/api/projects/status/bak6km5grc3j63s8?svg=true)](https://ci.appveyor.com/project/LowlyDBA/expresssql)
![GitHub Workflow Status (branch)](https://img.shields.io/github/workflow/status/LowlyDBA/ExpressSQL/Lint%20Code%20Base/master?label=lint%20code%20master)
[![codecov](https://codecov.io/gh/LowlyDBA/ExpressSQL/branch/master/graph/badge.svg)](https://codecov.io/gh/LowlyDBA/ExpressSQL)

A suite of T-SQL utility scripts for Microsoft SQL Server.

## Scripts

To quickly install or update all the scripts below, use `install_expsql.sql`.

| Name | Description |
| ---- | ----------- |
| [sp_sizeoptimiser](sp_sizeoptimiser.md) | Recommends space saving measures for data footprints, with special checks for SQL Server Express. |
| [sp_helpme](sp_helpme.md) |  A drop-in modern alternative to `sp_help`. |
| [sp_doc](sp_doc.md) | Always have current documentation by generating on the fly markdown documentation. |

## Compatibility

Tested on AppVeyor:

* SQL Server 2019
* SQL Server 2017
* SQL Server 2016
* SQL Server 2014
* SQL Server 2012 SP1

## More

Complimentary SQL Server Express guides at [expressdb.io](https://expressdb.io).

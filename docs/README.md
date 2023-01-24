# DBA MultiTool

[![License](https://img.shields.io/github/license/LowlyDBA/dba-multitool?color=blue)][license]
![Code Coverage](https://raw.githubusercontent.com/lowlydba/dba-multitool/_xml_coverage_reports/data/main/badge.svg)

[![Unit Test (Win SQL Server)](https://github.com/lowlydba/dba-multitool/actions/workflows/sqlserver-unit.yml/badge.svg)](https://github.com/lowlydba/dba-multitool/actions/workflows/sqlserver-unit.yml)
[![Unit Test (AzureSQL)](https://github.com/lowlydba/dba-multitool/actions/workflows/azuresql-unit.yml/badge.svg)](https://github.com/lowlydba/dba-multitool/actions/workflows/azuresql-unit.yml)
[![Lint Code](https://github.com/lowlydba/dba-multitool/actions/workflows/lint.yml/badge.svg)](https://github.com/lowlydba/dba-multitool/actions/workflows/lint.yml)

<img src="assets/dba-multitool-logo.png" align="left">

</br>The DBA MultiTool is a suite of scripts for the long haul:
optimizing storage, on-the-fly documentation, general administrative needs,
and more. Each script relies solely on T-SQL to ensure it is secure,
requires no third-party software, and can be installed in seconds.

## Scripts

To quickly install/update all the scripts, use install_dba-multitool.sql
or `Install-DbaMultiTool` from [dbatools :rocket:][dbatools].

For detailed instructions and documentation, see [dba-multitool.org](https://dba-multitool.org)

| Name | Description |
| ---- | ----------- |
| [sp_doc][sp_doc] | Always have current documentation by generating it on the fly in markdown. |
| [sp_estindex][sp_estindex] | Estimate a new index's size and statistics without having to create it. |
| [sp_helpme][sp_helpme] |  A drop-in modern alternative to `sp_help`. |
| [sp_sizeoptimiser][sp_sizeoptimiser] | Recommends space saving measures for data footprints, with special checks for SQL Server Express. |

## Compatibility

Only support for versions that are still in [mainstream][mainstream] support is guaranteed.

| Version | Tested |
| ------- | :----: |
| Azure SQL | :heavy_check_mark: |
| AWS RDS SQL Server * | :question: |
| SQL Server 2022 | :heavy_check_mark: |
| SQL Server 2019 | :heavy_check_mark: |
| SQL Server 2017 | :heavy_check_mark: |
| SQL Server 2014-2016 | :shrug: |
| <= SQL Server 2012 | :x: |

\* AWS RDS SQL Server is not tested, but should work *in theory*. YMMV.

## Contributing

* Want to help :construction_worker:? Check out the [contributing][contrib] doc
* Missing a feature? Found a :bug:? Open an [issue][issue] to get some :heart:
* Something else? Say hi in the SQL Server Community Slack [#multitool][slack] channel

<sub>*Icon made by [mangsaabguru](https://www.flaticon.com/authors/mangsaabguru)
from [www.flaticon.com](https://www.flaticon.com/)*</sub>

[contrib]: ../.github/CONTRIBUTING.md
[dbatools]: https://dbatools.io
[issue]: https://github.com/LowlyDBA/dba-multitool/issues
[license]: ../LICENSE
[mainstream]: https://learn.microsoft.com/en-us/sql/sql-server/end-of-support/sql-server-end-of-support-overview?view=sql-server-ver16#lifecycle-dates
[slack]: https://sqlcommunity.slack.com/archives/C026Y2YCM9N
[sp_doc]: https://dba-multitool.org/sp_doc
[sp_estindex]: https://dba-multitool.org/sp_estindex
[sp_helpme]: https://dba-multitool.org/sp_helpme
[sp_sizeoptimiser]: https://dba-multitool.org/sp_sizeoptimiser

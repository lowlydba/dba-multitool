# DBA MultiTool

[![License](https://img.shields.io/github/license/LowlyDBA/dba-multitool?color=blue)][license]
![Code Coverage](https://raw.githubusercontent.com/lowlydba/dba-multitool/_xml_coverage_reports/data/main/badge.svg)
[![brainmade.org](https://img.shields.io/badge/brainmade.org-000000?style=flat&logo=data%3Aimage%2Fsvg%2Bxml%3Bbase64%2CPHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIxZW0iIGhlaWdodD0iNzkiIHZpZXdCb3g9IjAgMCA2NyA3OSIgZmlsbD0ibm9uZSI%2BPHBhdGggZmlsbD0iI2ZmZiIgZD0iTTUyLjYxMiA3OC43ODJIMjMuMzNhMi41NTkgMi41NTkgMCAwIDEtMi41Ni0yLjU1OHYtNy42NzdoLTcuOTczYTIuNTYgMi41NiAwIDAgMS0yLjU2LTIuNTZWNTUuMzE1bC04LjgyLTQuMzk3YTIuNTU5IDIuNTU5IDAgMCAxLS45ODYtMy43MWw5LjgwNy0xNC43MTR2LTQuMzVDMTAuMjQgMTIuNTk5IDIyLjg0MyAwIDM4LjM4OCAwIDUzLjkzMiAwIDY2LjUzNCAxMi42IDY2LjUzOCAyOC4xNDNjLS42MzIgMjcuODI0LTEwLjc2IDIzLjUxNi0xMS4xOCAzNC4wNDVsLS4xODcgMTQuMDM1YTIuNTkgMi41OSAwIDAgMS0uNzUgMS44MSAyLjU1IDIuNTUgMCAwIDEtMS44MDkuNzVabS0yNi43MjMtNS4xMTdoMjQuMTY0bC4yODYtMTQuNTQyYy0uMjYzLTYuNjU2IDExLjcxNi04LjI0MyAxMS4wOC0zMC43MzQtLjM1OC0xMi43MTMtMTAuMzEzLTIzLjI3MS0yMy4wMzEtMjMuMjcxLTEyLjcxOCAwLTIzLjAyOSAxMC4zMDctMjMuMDMyIDIzLjAyNXY1LjExN2MwIC41MDYtLjE1IDEtLjQzIDEuNDJsLTguNjMgMTIuOTQxIDcuNjQ1IDMuODJhMi41NTkgMi41NTkgMCAwIDEgMS40MTUgMi4yOTF2OS42OTdoNy45NzRhMi41NTkgMi41NTkgMCAwIDEgMi41NiAyLjU1OXY3LjY3N1oiLz48cGF0aCBmaWxsPSIjZmZmIiBkPSJNNDAuMzcyIDU4LjIyMlYzOC45MzRjLjExOCAwIC4yMzcuMDE4LjM1NS4wMTggOS43NjktLjAxMiAxNy4wNS05LjAxMiAxNS4wMjItMTguNTY3YTIuMzY2IDIuMzY2IDAgMCAwLTEuODIxLTEuODIyYy04LjEwNi0xLjczLTE2LjEyMSAzLjI5Mi0xOC4wOTggMTEuMzQxLS4wMjQtLjAyNC0uMDQzLS4wNS0uMDY2LS4wNzNhMTUuMzIzIDE1LjMyMyAwIDAgMC0xNC4wNi00LjE3IDIuMzY1IDIuMzY1IDAgMCAwLTEuODIxIDEuODJjLTIuMDI4IDkuNTU1IDUuMjUyIDE4LjU1NCAxNS4wMiAxOC41NjguMjM2IDAgLjQ5Mi0uMDI4LjczOC0uMDR2MTIuMjEzaDQuNzMxWm0yLjgzOS0zMi4xNDNhMTAuNjQ2IDEwLjY0NiAwIDAgMSA4LjEyNC0zLjEwNmMuMzUgNi4zNC00Ljg4OCAxMS41NzctMTEuMjI4IDExLjIzYTEwLjU4IDEwLjU4IDAgMCAxIDMuMTA0LTguMTI0Wk0yNy40MDMgMzguMTkzYTEwLjYwNyAxMC42MDcgMCAwIDEtMy4xMTgtOC4xMjNjNi4zNDQtLjM1OCAxMS41ODcgNC44ODYgMTEuMjI4IDExLjIzLTMuMDIzLjE2OS01Ljk3My0uOTYxLTguMTEtMy4xMDdaIi8%2BPC9zdmc%2B)](https://brainmade.org/)
[![Unit Test (Win SQL Server)](https://github.com/lowlydba/dba-multitool/actions/workflows/sqlserver-unit.yml/badge.svg)](https://github.com/lowlydba/dba-multitool/actions/workflows/sqlserver-unit.yml)
[![Lint Code](https://github.com/lowlydba/dba-multitool/actions/workflows/lint.yml/badge.svg)](https://github.com/lowlydba/dba-multitool/actions/workflows/lint.yml)

<img src="assets/dba-multitool-logo.png" align="left">

</br>The DBA MultiTool is a suite of scripts for the long haul:
optimizing storage, on-the-fly documentation, general administrative needs,
and more. Each script relies solely on T-SQL to ensure it is secure,
requires no third-party software, and can be installed in seconds.

## Scripts

To install/update all the scripts, use install_dba-multitool.sql.

Looking for ways to automate the scripts? Try `Install-DbaMultiTool` from [dbatools :rocket:][dbatools],
or the Ansible collection [lowlydba.sqlserver][lowlydba.sqlserver].

For detailed instructions and documentation, see [the repo](https://github.com/lowlydba/dba-multitool)

| Name | Description |
| ---- | ----------- |
| sp_doc | Always have current documentation by generating it on the fly in markdown. |
| sp_estindex | Estimate a new index's size and statistics without having to create it. |
| sp_help_revlogin | Stored procedures that will help generate necessary scripts to transfer logins and their passwords. |
| sp_helpme |  A drop-in modern alternative to `sp_help`. |
| sp_sizeoptimiser | Recommends space saving measures for data footprints, with special checks for SQL Server Express. |

## Compatibility

Only support for versions that are still in [mainstream][mainstream] support is guaranteed.

| Version | Tested |
| ------- | :----: |
| Azure SQL | :heavy_check_mark: |
| AWS RDS SQL Server * | :question: |
| SQL Server 2022 | :heavy_check_mark: |
| SQL Server 2019 | :heavy_check_mark: |
| SQL Server 2014-2017 | :shrug: |
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
[lowlydba.sqlserver]: https://docs.ansible.com/ansible/latest/collections/lowlydba/sqlserver/index.html
[mainstream]: https://learn.microsoft.com/en-us/sql/sql-server/end-of-support/sql-server-end-of-support-overview?view=sql-server-ver16#lifecycle-dates
[slack]: https://sqlcommunity.slack.com/archives/C026Y2YCM9N
[sp_help_revlogin]: https://learn.microsoft.com/en-us/troubleshoot/sql/database-engine/security/transfer-logins-passwords-between-instances

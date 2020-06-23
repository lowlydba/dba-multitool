# Express SQL

[![apm](https://img.shields.io/apm/l/vim-mode.svg)](https://github.com/LowlyDBA/ExpressSQL/)
![AppVeyor branch](https://img.shields.io/appveyor/build/LowlyDBA/expresssql/master?label=appveyor%20master)
![GitHub Workflow Status (branch)](https://img.shields.io/github/workflow/status/LowlyDBA/ExpressSQL/Lint%20Code%20Base/master?label=lint%20code%20master)

A suite of T-SQL utility scripts for Microsoft SQL Server.

## Scripts

* :nut_and_bolt: [sp_sizeoptimiser](sp_sizeoptimiser.md) - Recommends 
space saving and corrective measures for minimal data footprints, with 
special checks for SQL Server Express to stay under database size limits.
* :grey_question: [sp_helpme](sp_helpme.md) - A drop-in modern alternative 
to `sp_help` to show more information.
* :page_facing_up: [sp_doc](sp_doc.md) - Always have up to date database 
documentation - `sp_doc` generates on the fly documentation in the form 
of GitHub markdown.

## Compatibility

Tested on AppVeyor:

* SQL Server 2019
* SQL Server 2017
* SQL Server 2016
* SQL Server 2014
* SQL Server 2012 SP1

## More

Complimentary SQL Server Express guides at [expressdb.io](https://expressdb.io).

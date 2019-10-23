[![license](https://img.shields.io/github/license/mashape/apistatus.svg)]()

# Purpose
The goal of this script is to generate tables using Git style Markdown from extended properties of common database objects. This allows for a free, extensible way to have a self-documenting database that can generate its own readme file alongside another solution to script a database into source control. 

It will create a table if properties exist for the following object types:

- Tables
- Views
- Columns
- Stored Procedures
- Inline Table Functions
- Scalar Functions
- Triggers
- Default Constraints
- Check Constraints

# Usage
The only parameter for this procedure is a database name, since the original usage scenario for this was to be included in a utility database:

    EXEC dbo.usp_genEPMarkdown @dbname = 'AdventureWorks'

It can be called via bcp to output a readme.md that can be directly placed inside of a git repo:

    bcp "EXEC dbo.usp_genEPMarkdown @dbname = 'AdventureWorks'" queryout readme.md -S myserver.com -c

# Compatibility
Only tested on SQL Server 2016 SP1 thus far, but should be backwards compatible through at least SQL 2008 R2.
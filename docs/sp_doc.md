[![license](https://img.shields.io/github/license/mashape/apistatus.svg)]()

# Purpose
The goal of this script is to generate tables using Git style Markdown from extended properties of common database objects. This allows for a free, extensible way to have a self-documenting database that can generate its own readme file.

It documents:

- Tables
- Views
- Stored Procedures
- Synonyms
- Scalar Functions
- Inline Table Functions
- Triggers - To be implemented
- Default Constraints - To be implemented
- Check Constraints - To be implemented

# Usage
The only parameter for this procedure is a database name, since the primary scenario for this is to be included in a utility database:

```tsql
    EXEC dbo.sp_doc @dbname = 'AdventureWorks'
```
To prevent data truncation, unwanted headers, etc. it can be called via sqlcmd to output directly to a readme.md file:

```tsql
    sqlcmd -S localhost -d master -Q "exec sp_doc @DatabaseName = 'WideWorldImporters';" -o readme.md -y 0
```

# Sample
Output for the [WideWorldImporters database](https://github.com/LowlyDBA/ExpressSQL/blob/master/docs/WideWorldImporters.md).

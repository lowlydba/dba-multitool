[![license](https://img.shields.io/github/license/mashape/apistatus.svg)]()

# Purpose
The goal of this script is to generate on the fly database documentation in Markdown. This allows for a free, extensible way to have a self-documenting database that can generate its own readme file.

It documents:

- Tables
	- Triggers
	- Default Constraints - To be implemented
	- Check Constraints - To be implemented
- Views
- Stored Procedures
- Synonyms
- Scalar Functions
- Inline Table Functions


# Usage
The only parameter for this procedure is a database name, since the primary scenario for this is to be included in a utility database:

```tsql
    EXEC dbo.sp_doc @dbname = 'AdventureWorks'
```
To prevent data truncation, unwanted headers, etc. it can be called via sqlcmd to output directly to a readme.md file:

```
    sqlcmd -S localhost -d master -Q "exec sp_doc @DatabaseName = 'WideWorldImporters';" -o readme.md -y 0
```

# Sample
Output for the [WideWorldImporters database](https://github.com/LowlyDBA/ExpressSQL/blob/master/docs/WideWorldImporters.md).

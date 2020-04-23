[![license](https://img.shields.io/github/license/mashape/apistatus.svg)]()

# Purpose
The goal of this script is to generate on the fly database documentation in Github Flavor Markdown (GFM). This allows for a free, extensible way to have a self-documenting database that can generate its own readme file.

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

```sql
    EXEC dbo.sp_doc @dbname = 'AdventureWorks'
```
To prevent data truncation, unwanted headers, etc. it can be called via sqlcmd to output directly to a readme.md file:

```batchfile
    sqlcmd -S localhost -d master -Q "exec sp_doc @DatabaseName = 'WideWorldImporters';" -o readme.md -y 0
```

*Note: Due to differences between HTML and GFM, output may not be 100% functional if a markdown file is converted via Github Pages.*

# Sample
Output for the [WideWorldImporters database](https://github.com/LowlyDBA/ExpressSQL/blob/master/docs/WideWorldImporters.md).

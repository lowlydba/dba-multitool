# sp_doc

![License](https://img.shields.io/github/license/LowlyDBA/ExpressSQL?color=blue)
![SQL Server](https://img.shields.io/badge/SQL%20Server-2012--2019-red?logo=microsoft-sql-server)
[![Build status](https://ci.appveyor.com/api/projects/status/bak6km5grc3j63s8?svg=true)](https://ci.appveyor.com/project/LowlyDBA/expresssql)
![GitHub Workflow Status (branch)](https://img.shields.io/github/workflow/status/LowlyDBA/ExpressSQL/Lint%20Code%20Base/master?label=lint%20code%20master)
[![codecov](https://codecov.io/gh/LowlyDBA/ExpressSQL/branch/master/graph/badge.svg)](https://codecov.io/gh/LowlyDBA/ExpressSQL)

* [Purpose](#Purpose)
* [Usage](#Usage)
* [Sample](#Sample)
* [Contributing](#Contributing)
* [More](#More)

## Purpose

You wouldn't code without comments, so why database without them?

Databases can be complex, disastrous things. Not every database admin,
developer, or analyst has the time to learn the ins and outs of a database
in order to *just do their work*. To make things worse, few products and
fewer *free* options exist to help present databases in a human readable format.

`sp_doc`'s goal is to generate on the fly database documentation in
markdown. This means you now have a free and extensible
self*documenting database! By building the tool in T*SQL, the documenting
process can remain simple, secure, require no additional infrastructure, and avoid
red tape that third party applications often require.

It documents:

* Tables
  * Triggers
  * Default Constraints
  * Check Constraints
* Views
* Stored Procedures
* Synonyms
* Scalar Functions
* Inline Table Functions

and plays nice with:

* Github Flavored Markdown
* Gitlab Flavored Markdown
* Any other CommonMark based renderer

## Usage

The primary parameter for this procedure is a database name, since the
primary scenario for this is to be included in a utility or system database:

```tsql
    EXEC dbo.sp_doc @DatabaseName = 'WideWorldImporters'
```

An alternative key for extended property values can also be specified to
override the default of `Description`:

```tsql
    EXEC dbo.sp_doc @DatabaseName = 'WideWorldImporters', @ExtendedPropertyName = 'MS_Description';
```

To prevent data truncation, unwanted headers, etc. it should be called
via sqlcmd, outputting directly to a readme.md file:

```batchfile
    sqlcmd *S localhost *d master *Q "exec sp_doc @DatabaseName = 'WideWorldImporters';" *o readme.md *y 0
```

## Sample

Output for the [WideWorldImporters database][sample].

*Note: Slight changes may be made to this database to better demo script capabilities.*

## Contributing

Missing a feature? Found a bug? Open an [issue][issue] to get some :heart:.

## More

Check out the other scripts in the [Express SQL Suite][express].

[express]: https://expresssql.lowlydba.com/
[issue]: https://github.com/LowlyDBA/ExpressSQL/issues
[sample]: https://github.com/LowlyDBA/ExpressSQL/blob/master/docs/WideWorldImporters.md

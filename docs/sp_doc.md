# sp_doc

* [Purpose](#purpose)
* [Arguments](#arguments)
* [Usage](#usage)
* [Output](#output)
* [Known Issues](#known-issues)
* [Contributing](#contributing)
* [More](#more)

## Purpose

You wouldn't code without comments, so why database without them?

Databases can be complex, disastrous things. Not every database admin,
developer, or analyst has the time to learn the ins and outs of a database
in order to *just do their work*. To make things worse, few products and
fewer *free* options exist to help present databases in a human readable format.

`sp_doc`'s goal is to generate on the fly database documentation in
markdown. This means you now have a free and extensible
self-documenting database! By building the tool in T-SQL, the documenting
process can remain simple, secure, require no additional infrastructure, and avoid
red tape that third party applications often require.

It documents:

* Tables
  * Triggers
  * Default Constraints
  * Check Constraints
  * Indexes
* Views
  * Indexes
* Stored Procedures
* Synonyms
* Scalar Functions
* Inline Table Functions
* User Defined Table Types
* Extended Properties
* Sensitivity Classifications (2019+)

and plays nice with:

* Github Flavored Markdown
* Gitlab Flavored Markdown
* Any other CommonMark based renderer

## Arguments

| Parameter | Type | Output | Description |
| --- | --- | --- | --- |
| @DatabaseName | SYSNAME(128) | no | Target database to document. Default is the stored procedure's database. |
| @ExtendedPropertyName | SYSNAME(128) | no | Key for extended properties on objects. Default is 'Description'. |
| @LimitStoredProcLength | BIT | no | Limit stored procedure contents to 8000 characters, to avoid memory issues with some IDEs. Default is 1. |
| @Emojis | BIT | no | Use emojis when generating documentation. Default is 0. |
| @Verbose | BIT | no | Whether or not to print additional information during the script run. Default is 0. |
| @SqlMajorVersion | TINYINT | no | Used for unit testing purposes only. |
| @SqlMinorVersion | SMALLINT | no | Used for unit testing purposes only. |

## Usage

### Basic Use

```tsql
EXEC dbo.sp_doc @DatabaseName = 'WideWorldImporters'
```

```tsql
EXEC dbo.sp_doc @DatabaseName = 'WideWorldImporters', @ExtendedPropertyName = 'MS_Description';
```

### Output to File

Batch:

```batchfile
sqlcmd -S localhost -d master -Q "exec sp_doc @DatabaseName = 'WideWorldImporters';" -o readme.md -y 0
```

PowerShell / DbaTools:

```powershell
$Query = "EXEC sp_doc @DatabaseName = 'WideWorldImporters';"
Invoke-DbaQuery -SqlInstance localhost -Database master -Query $Query -As SingleValue | Out-File readme.md
```

### Advanced Use

#### Stored Procedure Parameters

Add extended properties to programmable objects, using parameter names as keys,
to include their descriptions in the documentation:

```tsql
EXEC sys.sp_addextendedproperty @name=N'@ExtendedPropertyName',
    @value=N'Key for extended properties on objects. Default is ''Description''.' ,
    @level0type=N'SCHEMA',@level0name=N'dbo',
    @level1type=N'PROCEDURE',
    @level1name=N'sp_doc'
```

#### Embedded Markdown

Extended properties containing embedded markdown are supported. The following characters
are replaced to render markdown as plain text to avoid issues with formatting:

| Character | Replacement | Description |
| --------- | ----------- | ----------- |
| `\|` | `&#124;` | HTML code for pipe |
| ``` ` ``` | `&#96;` | HTML code for tick |
| `Newline` | `<br/>` | HTML tag for line break |

## Output

Sample output for the [WideWorldImporters database][sample].

*Note: Slight changes may be made to this database to better demo script capabilities.*

## Known Issues

### Missing Line Breaks

When executing in SSMS, even with ['Retain CR/LF on copy or save'][so]
setting enabled, line breaks may incorrectly
not appear in the results.
A [UserVoice bug][UVBug] has been opened - please vote if you
agree it should be addressed.

This should not affect the markdown rendering, but it is
recommended to use another application for execution
until this is fixed.

## Contributing

Missing a feature? Found a bug? Open an [issue][issue] to get some :heart:

## More

Check out the other scripts in the [DBA MultiTool][tool].

[tool]: https://dba-multitool.org
[issue]: https://github.com/LowlyDBA/dba-multitool/issues
[sample]: assets/WideWorldImporters.md
[so]: https://stackoverflow.com/a/37284582/4406684
[UVBug]: https://feedback.azure.com/forums/908035-sql-server/suggestions/43188567-sql-server-management-studio-removing-trailing-crl
# sp_estindex

![sp_estindex constellation logo](assets/constellation.png "sp_estindex constellation logo")

* [Purpose](#purpose)
* [Arguments](#arguments)
* [Usage](#usage)
* [Output](#output)
* [Contributing](#contributing)
* [More](#more)

## Purpose

In complex environments, sometimes the best ways to create indexes aren't
the most obvious. Table size, underlying statistics, missing index
recommendations, fill factors, and uniqueness are just *some* of the
factors that need to be considered. But these can be difficult to
aggregate and experiment with since index creation has a very real
cost of time and compute power in large databases.

To make index planning easier, `sp_estindex` gives you statistics on
how an index would look without having to actually create it!

## Arguments

| Parameter | Type | Output | Description |
| --- | --- | --- | --- |
| @SchemaName | SYSNAME(128) | no | Target schema of the index's table. Default is 'dbo'. |
| @TableName | SYSNAME(128) | no | Target table for the index. Default is current database. |
| @DatabaseName | SYSNAME(128) | no | Target database of the index's table. |
| @IndexColumns | NVARCHAR(2048) | no | Comma separated list of key columns. |
| @IncludeColumns | NVARCHAR(2048) | no | Optional comma separated list of include columns. |
| @IsUnique | BIT | no | Whether or not the index is UNIQUE. Default is 0. |
| @Filter | NVARCHAR(2048) | no | Optional filter for the index. |
| @FillFactor | TINYINT | no | Optional fill factor for the index. Default is 100. |
| @Verbose | BIT | no | Show intermediate variables used in size calculations. Default is 0. |
| @SqlMajorVersion | TINYINT | no | For unit testing only. |

## Usage

```tsql
EXEC dbo.sp_estindex @SchemaName = 'dbo', @tableName = 'Marathon', @IndexColumns = 'racer_id, finish_time';
```

```tsql
EXEC dbo.sp_estindex @tableName = 'Marathon', @IndexColumns = 'racer_id, finish_time', @Filter = 'WHERE racer_id IS NOT NULL', @FillFactor = 90;
```

## Output

For `[Sales].[Invoices]` in WorldWideImporters:

*Note: There is no missing index match in this example,
so the penultimate result set is empty.*

![sp_estindex output](assets/sp_estindex_output.png)

## Contributing

Missing a feature? Found a bug? Open an [issue][issue] to get some :heart:

## More

Check out the other scripts in the [DBA MultiTool][tool].

[tool]: http://dba-multitool.org
[issue]: https://github.com/LowlyDBA/dba-multitool/issues

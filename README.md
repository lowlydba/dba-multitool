[![Build status](https://ci.appveyor.com/api/projects/status/bak6km5grc3j63s8/branch/master?svg=true)](https://ci.appveyor.com/project/LowlyDBA/expresssql)


# sp_sizeoptimiser

A stored procedure that recommends space saving and corrective data type measures based on SQL Server database schemas. Great for quickly assessing databases that may have non-optimal data types. Especially useful for SQL Server Express to help stay under the 10GB file size limitations.

Storage is cheap, but smaller is faster!

# Checks

There are 13 checks currently supported:

* [Time based formats](#time-based-formats)
* [Unspecified VARCHAR length](#unspecified-varchar-length)

### Time based formats

Checks that commonly named time columns are using one of the recommended date/time data types. Storing date/time data in other data types may take up more storage and cause performance issues.

### Unspecified VARCHAR length

If a [`VARCHAR`](https://docs.microsoft.com/en-us/sql/t-sql/data-types/char-and-varchar-transact-sql?view=sql-server-2017) column is created without specifying a length, it defaults to one. If this is done by mistake, it may cause truncation of data as it is inserted into the table. If only one character is needed, `CHAR(1)` is preferable as it uses 2 less bytes than `VARCHAR(1)`.

# Compatibility

Tested on:

* SQL 2017
* SQL 2016
* SQL 2014
* SQL 2012 SP1
* SQL 2008 R2 SP2

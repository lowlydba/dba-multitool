[![apm](https://img.shields.io/apm/l/vim-mode.svg)](https://github.com/LowlyDBA/ExpressSQL/)
[![Build status](https://ci.appveyor.com/api/projects/status/bak6km5grc3j63s8/branch/master?svg=true)](https://ci.appveyor.com/project/LowlyDBA/expresssql)




# sp_sizeoptimiser

A stored procedure that recommends space saving and corrective data type measures based on SQL Server database schemas. Great for quickly assessing databases that may have non-optimal data types. Especially useful for SQL Server Express to help stay under the 10GB file size limitations.

Storage is cheap, but smaller is faster!

# Checks

There are 14 checks currently supported:

## Data Types
* [Time based data types](#time-based-formats)
* [Arbitrary VARCHAR length](#arbitrary-varchar-length)
* [Unspecified VARCHAR length](#unspecified-varchar-length)
* [Mad VARCHAR Max](#mad-varchar-max)
* [NVARCHAR in Express](#nvarchar-in-express) *(Express only)*

## File Growth
* [Database growth past 10GB](#database-growth-past-10GB) *(Express only)*
* [Database growth type](#database-growth-type)

### Time based formats

Checks that commonly named time columns are using one of the recommended date/time data types. Storing date/time data in other data types may take up more storage and cause performance issues.

### Arbitrary VARCHAR length

A variable length column should be based off of business requirements and only be as large as the  maximum amount of data needed to be stored. Using classic numbers like 256/255 to estimate the length of a column usually indicate that the exact length required has not been properly assessed.

### Unspecified VARCHAR length

If a [`VARCHAR`](https://docs.microsoft.com/en-us/sql/t-sql/data-types/char-and-varchar-transact-sql?view=sql-server-2017) column is created without specifying a length, it defaults to one. If this is done by mistake, it may cause truncation of data as it is inserted into the table. If only one character is needed, `CHAR(1)` is preferable as it uses 2 less bytes than `VARCHAR(1)`.

### Mad VARCHAR Max

While using `VARCHAR(MAX)`/`NVARCHAR(MAX)` can be tempting as a one size fits all solution, it is generally bad design practice unless absolutely required. It limits the column's ability to be used as an index key, makes online index rebuilding impossible, can lead to storing data pages out of row, performance will generally suffer, and more.

### NVARCHAR in Express

With the database size limit of 10GB for user databases in SQL Server Express, choosing the smallest data types is integral. Avoid NVARCHAR unless the column requires Unicode data. Instead, VARCHAR will only use approximately half of the space to store similar data.

### Database growth past 10GB

In most versions SQL Server Express, user databases and the model database are subject to a limit of 10GB. Setting the file growth limit to stay under that amount helps to prevent the database from auto growing too large and being unable to function properly.

### Database growth type

Setting data file growth to be a fixed value, versus a percentage,
helps to avoid exponential growth of the files. A percentage will result in the file growing significantly larger over time during each auto growth event.

# Compatibility

Tested on:

* SQL 2017
* SQL 2016
* SQL 2014
* SQL 2012 SP1
* SQL 2008 R2 SP2

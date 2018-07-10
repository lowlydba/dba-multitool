[![Build status](https://ci.appveyor.com/api/projects/status/bak6km5grc3j63s8/branch/master?svg=true)](https://ci.appveyor.com/project/LowlyDBA/expresssql)


# sp_sizeoptimiser

A stored procedure that recommends space saving and corrective data type measures based on SQL Server database schemas. Great for quickly assessing databases that may have non-optimal data types. Especially useful for SQL Server Express to help stay under the 10GB file size limitations.

Storage is cheap, but smaller is faster!

# Checks

There are 13 checks currently supported:

* [Time based formats](#time-based-formats)

### Time based formats

Checks that commonly named time columns are using one of the recommended date/time data types. Storing date/time data in other data types may take up more storage and cause performance issues. 

# Compatibility

Tested on:

* SQL 2008 R2
* SQL 2017

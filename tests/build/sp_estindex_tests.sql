/************************************
Begin sp_estindex tests
*************************************/

--Clean Class
EXEC tSQLt.DropClass 'sp_estindex';
GO

EXEC tSQLT.NewTestClass 'sp_estindex';
GO

/******************************
Success Cases
******************************/

/*
test that sp_estindex exists
*/
CREATE PROCEDURE [sp_estindex].[test sp succeeds on create]
AS
BEGIN

--Build
DECLARE @ObjectName SYSNAME = 'dbo.sp_estindex';
DECLARE @Message NVARCHAR(MAX) = 'Stored procedure sp_estindex does not exist.';

--Assert
EXEC tSQLt.AssertObjectExists @objectName = @ObjectName, @message = @Message;

END;
GO

/*
test success on supported SQL Server >= v12
*/
CREATE PROCEDURE [sp_estindex].[test sp succeeds on supported version]
AS
BEGIN;

--Build
DECLARE @version TINYINT = 13;
DECLARE @Verbose BIT = 0;
DECLARE @command NVARCHAR(MAX) = CONCAT('EXEC [dbo].[sp_estindex] @SqlMajorVersion = ', @version, ', @TableName = ''CaptureOutputLog'', @IndexColumns = ''Id'', @SchemaName = ''tSQLt'', @Verbose =', @Verbose, ';');

--Assert
EXEC [tSQLt].[ExpectNoException]
EXEC [tSQLt].[SuppressOutput] @command = @command;

END;
GO

/*
test success on unique index
*/
CREATE PROCEDURE [sp_estindex].[test sp succeeds on unique index]
AS
BEGIN;

--Build
DECLARE @Verbose BIT = 0;
DECLARE @IsUnique BIT = 1;
DECLARE @command NVARCHAR(MAX) = CONCAT('EXEC [dbo].[sp_estindex] @IsUnique = ',@IsUnique, ' @TableName = ''CaptureOutputLog'', @IndexColumns = ''Id'', @SchemaName = ''tSQLt'', @Verbose =', @Verbose, ';');

--Assert
EXEC [tSQLt].[ExpectNoException]
EXEC [tSQLt].[SuppressOutput] @command = @command;

END;
GO


/*
test success on filtered index
*/
CREATE PROCEDURE [sp_estindex].[test sp succeeds on filtered index]
AS
BEGIN;

--Build
DECLARE @Verbose BIT = 0;
DECLARE @Filter VARCHAR(50) = 'WHERE ID IS NOT NULL';
DECLARE @command NVARCHAR(MAX) = CONCAT('EXEC [dbo].[sp_estindex] @Filter = ''',@Filter ,
    ''', @TableName = ''CaptureOutputLog'', @IndexColumns = ''Id'', @SchemaName = ''tSQLt'', @Verbose =', @Verbose, ';');

--Assert
EXEC [tSQLt].[ExpectNoException]
EXEC [tSQLt].[SuppressOutput] @command = @command;

END;
GO

/*
test success on non-default fill factor
*/
CREATE PROCEDURE [sp_estindex].[test sp succeeds on non-default fill factor]
AS
BEGIN;

--Build
DECLARE @Verbose BIT = 0;
DECLARE @FillFactor TINYINT = 50
DECLARE @command NVARCHAR(MAX) = CONCAT('EXEC [dbo].[sp_estindex] @FillFactor = ',@FillFactor ,
    ', @TableName = ''CaptureOutputLog'', @IndexColumns = ''Id'', @SchemaName = ''tSQLt'', @Verbose =', @Verbose, ';');

--Assert
EXEC [tSQLt].[ExpectNoException]
EXEC [tSQLt].[SuppressOutput] @command = @command;

END;
GO

/*
test success with included columns
*/
CREATE PROCEDURE [sp_estindex].[test sp succeeds with included columns]
AS
BEGIN;

--Build
DECLARE @Verbose BIT = 1;
DECLARE @IncludeColumns VARCHAR(50) = 'OutputText'
DECLARE @IndexColumns VARCHAR(50) = 'Id';
DECLARE @SchemaName SYSNAME = 'tSQLt';
DECLARE @TableName SYSNAME = 'CaptureOutputLog';

DECLARE @command NVARCHAR(MAX) = CONCAT('EXEC [dbo].[sp_estindex] @IncludeColumns = ''',@IncludeColumns ,
    ''', @TableName = ''', @TableName, ''', @IndexColumns = ''',@IndexColumns, ''', @SchemaName = ''', @SchemaName, ''', @Verbose =', @Verbose, ';');

--Assert
EXEC [tSQLt].[ExpectNoException]
EXEC [tSQLt].[SuppressOutput] @command = @command;

END;
GO


/*
test success with unique index on heap
*/
CREATE PROCEDURE [sp_estindex].[test sp succeeds with unique index on heap]
AS
BEGIN;

--Build
DECLARE @Verbose BIT = 1;
DECLARE @IndexColumns VARCHAR(50) = 'ID';
DECLARE @TableName SYSNAME = '##Heap';
DECLARE @IsUnique BIT = 1
DECLARE @DatabaseName SYSNAME = 'tempdb';

CREATE TABLE ##Heap(
ID INT);

INSERT INTO ##Heap (ID)
SELECT TOP 1000 ROW_NUMBER() OVER(ORDER BY t1.number) AS N
FROM [master]..[spt_values] [t1] 
       CROSS JOIN [master]..[spt_values] [t2];

DECLARE @command NVARCHAR(MAX) = CONCAT('EXEC [dbo].[sp_estindex] @DatabaseName =''', @DatabaseName, ''', @TableName = ''', @TableName, ''', @IndexColumns = ''',@IndexColumns, ''', @IsUnique =', @IsUnique, ', @Verbose =', @Verbose, ';');

--Assert
EXEC [tSQLt].[ExpectNoException]
EXEC [tSQLt].[SuppressOutput] @command = @command;

--Teardown
DROP TABLE ##Heap;

END;
GO

/*
test success with unique index on heap
*/
CREATE PROCEDURE [sp_estindex].[test sp succeeds with non-unique index on heap]
AS
BEGIN;

--Build
DECLARE @Verbose BIT = 1;
DECLARE @IndexColumns VARCHAR(50) = 'ID';
DECLARE @TableName SYSNAME = '##Heap';
DECLARE @IsUnique BIT = 0;
DECLARE @DatabaseName SYSNAME = 'tempdb';

CREATE TABLE ##Heap(
ID INT);

INSERT INTO ##Heap (ID)
SELECT TOP 1000 ROW_NUMBER() OVER(ORDER BY t1.number) AS N
FROM [master]..[spt_values] [t1] 
       CROSS JOIN [master]..[spt_values] [t2];

DECLARE @command NVARCHAR(MAX) = CONCAT('EXEC [dbo].[sp_estindex] @DatabaseName =''', @DatabaseName, ''', @TableName = ''', @TableName, ''', @IndexColumns = ''',@IndexColumns, ''', @IsUnique =', @IsUnique, ', @Verbose =', @Verbose, ';');

--Assert
EXEC [tSQLt].[ExpectNoException]
EXEC [tSQLt].[SuppressOutput] @command = @command;

--Teardown
DROP TABLE ##Heap;

END;
GO

/*
test success with unique index on clustered
*/
CREATE PROCEDURE [sp_estindex].[test sp succeeds with unique index on clustered]
AS
BEGIN;

--Build
DECLARE @Verbose BIT = 1;
DECLARE @IndexColumns VARCHAR(50) = 'ID';
DECLARE @TableName SYSNAME = '##Clustered';
DECLARE @DatabaseName SYSNAME = 'tempdb';
DECLARE @IsUnique BIT = 1;
DECLARE @TeardownSql NVARCHAR(MAX) = N'';

CREATE TABLE ##Clustered(
ID INT);

INSERT INTO ##Clustered (ID)
SELECT TOP 1000 ROW_NUMBER() OVER(ORDER BY t1.number) AS N
FROM [master]..[spt_values] [t1] 
       CROSS JOIN [master]..[spt_values] [t2];
CREATE CLUSTERED INDEX cdx_temporary ON ##Clustered(ID);

DECLARE @command NVARCHAR(MAX) = CONCAT('EXEC [dbo].[sp_estindex] @DatabaseName =''', @DatabaseName, ''', @TableName = ''', @TableName, ''', @IsUnique =', @IsUnique, ', @IndexColumns = ''',@IndexColumns, ''', @Verbose =', @Verbose, ';');

--Assert
EXEC [tSQLt].[ExpectNoException]
EXEC [tSQLt].[SuppressOutput] @command = @command;

--Teardown
DROP TABLE ##Clustered;

END;
GO


/*
test success with multi-leaf index
*/
CREATE PROCEDURE [sp_estindex].[test sp succeeds with multi-leaf index]
AS
BEGIN;

--Build
DECLARE @Verbose BIT = 1;
DECLARE @IndexColumns VARCHAR(50) = 'ID';
DECLARE @TableName SYSNAME = '##Clustered';
DECLARE @DatabaseName SYSNAME = 'tempdb';
DECLARE @IsUnique BIT = 1;
DECLARE @TeardownSql NVARCHAR(MAX) = N'';

CREATE TABLE ##Clustered(
ID INT);

INSERT INTO ##Clustered (ID)
SELECT TOP 1000000 ROW_NUMBER() OVER(ORDER BY t1.number) AS N
FROM [master]..[spt_values] [t1] 
       CROSS JOIN [master]..[spt_values] [t2];

DECLARE @command NVARCHAR(MAX) = CONCAT('EXEC [dbo].[sp_estindex] @DatabaseName =''', @DatabaseName, ''', @TableName = ''', @TableName, ''', @IsUnique =', @IsUnique, ', @IndexColumns = ''',@IndexColumns, ''', @Verbose =', @Verbose, ';');

--Assert
EXEC [tSQLt].[ExpectNoException]
EXEC [tSQLt].[SuppressOutput] @command = @command;

--Teardown
DROP TABLE ##Clustered;

END;
GO

/*
test success with non-unique index on clustered
*/
CREATE PROCEDURE [sp_estindex].[test sp succeeds with non-unique index on clustered]
AS
BEGIN;

--Build
DECLARE @Verbose BIT = 1;
DECLARE @IndexColumns VARCHAR(50) = 'ID';
DECLARE @TableName SYSNAME = '##Clustered';
DECLARE @DatabaseName SYSNAME = 'tempdb';
DECLARE @IsUnique BIT = 0;

CREATE TABLE ##Clustered(
ID INT);

INSERT INTO ##Clustered (ID)
SELECT TOP 1000 ROW_NUMBER() OVER(ORDER BY t1.number) AS N
FROM [master]..[spt_values] [t1] 
       CROSS JOIN [master]..[spt_values] [t2];

CREATE CLUSTERED INDEX cdx_temporary ON ##Clustered(ID);
DECLARE @command NVARCHAR(MAX) = CONCAT('EXEC [dbo].[sp_estindex] @DatabaseName =''', @DatabaseName, ''', @TableName = ''', @TableName, ''', @IsUnique =', @IsUnique, ', @IndexColumns = ''',@IndexColumns, ''', @Verbose =', @Verbose, ';');

--Assert
EXEC [tSQLt].[ExpectNoException]
EXEC [tSQLt].[SuppressOutput] @command = @command;

--Teardown
DROP TABLE ##Clustered;

END;
GO

/*
test success with existing ##TempMissingIndex
*/
CREATE PROCEDURE [sp_estindex].[test sp succeeds with existing ##TempMissingIndex]
AS
BEGIN;

--Build
DECLARE @Verbose BIT = 1;
DECLARE @IncludeColumns VARCHAR(50) = 'OutputText'
DECLARE @IndexColumns VARCHAR(50) = 'Id';
DECLARE @SchemaName SYSNAME = 'tSQLt';
DECLARE @TableName SYSNAME = 'CaptureOutputLog';

SELECT 1 AS [one]
INTO ##TempMissingIndex;

DECLARE @command NVARCHAR(MAX) = CONCAT('EXEC [dbo].[sp_estindex] @TableName = ''', @TableName, ''', @IndexColumns = ''',@IndexColumns, ''', @SchemaName = ''', @SchemaName, ''', @Verbose =', @Verbose, ';');

--Assert
EXEC [tSQLt].[ExpectNoException]
EXEC [tSQLt].[SuppressOutput] @command = @command;

END;
GO

/*
test success with nullable columns
*/
CREATE PROCEDURE [sp_estindex].[test sp succeeds with nullable columns]
AS
BEGIN;

--Build
DECLARE @Verbose BIT = 0;
DECLARE @IndexColumns VARCHAR(50) = 'name';
DECLARE @SchemaName SYSNAME = 'tSQLt';
DECLARE @TableName SYSNAME = 'Private_AssertEqualsTableSchema_Actual';

DECLARE @command NVARCHAR(MAX) = CONCAT('EXEC [dbo].[sp_estindex] @TableName = ''', @TableName, ''', @IndexColumns = ''',@IndexColumns, ''', @SchemaName = ''', @SchemaName, ''', @Verbose =', @Verbose, ';');

--Assert
EXEC [tSQLt].[ExpectNoException]
EXEC [tSQLt].[SuppressOutput] @command = @command;

END;
GO

/*
test success with variable len columns
*/
CREATE PROCEDURE [sp_estindex].[test sp succeeds with variable len columns]
AS
BEGIN;

--Build
DECLARE @Verbose BIT = 0;
DECLARE @IndexColumns VARCHAR(50) = 'name';
DECLARE @SchemaName SYSNAME = 'tSQLt';
DECLARE @TableName SYSNAME = 'Private_AssertEqualsTableSchema_Actual';

DECLARE @command NVARCHAR(MAX) = CONCAT('EXEC [dbo].[sp_estindex] @TableName = ''', @TableName, ''', @IndexColumns = ''',@IndexColumns, ''', @SchemaName = ''', @SchemaName, ''', @Verbose =', @Verbose, ';');

--Assert
EXEC [tSQLt].[ExpectNoException]
EXEC [tSQLt].[SuppressOutput] @command = @command;

END;
GO

/*
test success with verbose mode
*/
CREATE PROCEDURE [sp_estindex].[test sp succeeds with verbose mode]
AS
BEGIN;

--Build
DECLARE @Verbose BIT = 1;
DECLARE @IndexColumns VARCHAR(50) = 'name';
DECLARE @SchemaName SYSNAME = 'tSQLt';
DECLARE @TableName SYSNAME = 'Private_AssertEqualsTableSchema_Actual';

DECLARE @command NVARCHAR(MAX) = CONCAT('EXEC [dbo].[sp_estindex] @TableName = ''', @TableName, ''', @IndexColumns = ''',@IndexColumns, ''', @SchemaName = ''', @SchemaName, ''', @Verbose =', @Verbose, ';');

--Assert
EXEC [tSQLt].[ExpectNoException]
EXEC [tSQLt].[SuppressOutput] @command = @command;

END;
GO

/*
test success with variable len include columns
*/
CREATE PROCEDURE [sp_estindex].[test sp succeeds with variable len include columns]
AS
BEGIN;

--Build
DECLARE @Verbose BIT = 0;
DECLARE @IndexColumns VARCHAR(50) = 'restore_history_id';
DECLARE @IncludeColumns VARCHAR(50) = 'destination_database_name';
DECLARE @SchemaName SYSNAME = 'dbo';
DECLARE @DatabaseName SYSNAME = 'msdb';
DECLARE @TableName SYSNAME = 'restorehistory';

DECLARE @command NVARCHAR(MAX) = CONCAT('EXEC [dbo].[sp_estindex] @TableName = ''', @TableName, ''', @DatabaseName = ''',@DatabaseName, ''', @IndexColumns = ''',@IndexColumns, ''', @IncludeColumns = ''',@IncludeColumns, ''', @SchemaName = ''', @SchemaName, ''', @Verbose =', @Verbose, ';');

--Assert
EXEC [tSQLt].[ExpectNoException]
EXEC [tSQLt].[SuppressOutput] @command = @command;

END;
GO


/*
test success without @SchemaName
*/
CREATE PROCEDURE [sp_estindex].[test sp succeeds without @SchemaName]
AS
BEGIN;

--Build
DECLARE @Verbose BIT = 0;
DECLARE @IndexColumns VARCHAR(50) = 'first_family_number';
DECLARE @DatabaseName SYSNAME = 'msdb'
DECLARE @TableName SYSNAME = 'backupfile';

DECLARE @command NVARCHAR(MAX) = CONCAT('EXEC [dbo].[sp_estindex] @TableName = ''', @TableName, ''', @DatabaseName = ''', @DatabaseName, ''', @IndexColumns = ''',@IndexColumns, ''', @Verbose =', @Verbose, ';');

--Assert
EXEC [tSQLt].[ExpectNoException]
EXEC [tSQLt].[SuppressOutput] @command = @command;

END;
GO

/************************************
Failure cases
*************************************/

/*
test failure on unsupported SQL Server < v12
*/
CREATE PROCEDURE [sp_estindex].[test sp fails on unsupported version]
AS
BEGIN;

--Build
DECLARE @version TINYINT = 10;
DECLARE @Verbose BIT = 0;
DECLARE @TableName VARCHAR(50) = 'DoesntMatter';
DECLARE @IndexColumns VARCHAR(50) = 'AlsoDoesntMatter';

DECLARE @ExpectedMessage NVARCHAR(MAX) = '[sp_estindex]: SQL Server versions below 2012 are not supported, sorry!';
DECLARE @ExpectedSeverity TINYINT = 16;
DECLARE @ExpectedState TINYINT = 1;
DECLARE @ExpectedErrorNumber INT = 50000;

--Assert
EXEC [tSQLt].[ExpectException] @ExpectedMessage = @ExpectedMessage, @ExpectedSeverity = @ExpectedSeverity, @ExpectedState = @ExpectedState, @ExpectedErrorNumber = @ExpectedErrorNumber
EXEC [dbo].[sp_estindex] @SqlMajorVersion = @version, @TableName = @TableName, @IndexColumns = @IndexColumns, @Verbose = @Verbose;

END;
GO

/*
test failure with no @IndexColumns
*/
CREATE PROCEDURE [sp_estindex].[test sp fails with no @IndexColumns]
AS
BEGIN;

--Build
DECLARE @Verbose BIT = 0;
DECLARE @TableName VARCHAR(50) = 'DoesntMatter';
DECLARE @ExpectedMessage NVARCHAR(MAX) = N'Procedure or function ''sp_estindex'' expects parameter ''@IndexColumns'', which was not supplied.';
DECLARE @ExpectedSeverity TINYINT = 16;
DECLARE @ExpectedState TINYINT = 4;
DECLARE @ExpectedErrorNumber INT = 201;

--Assert
EXEC [tSQLt].[ExpectException] @ExpectedMessage = N'', @ExpectedSeverity = @ExpectedSeverity, @ExpectedState = @ExpectedState, @ExpectedErrorNumber = @ExpectedErrorNumber;
EXEC [dbo].[sp_estindex] @TableName = @TableName, @Verbose = @Verbose;

END;
GO

/*
test failure with no @TableName
*/
CREATE PROCEDURE [sp_estindex].[test sp fails with no @TableName]
AS
BEGIN;

--Build
DECLARE @Verbose BIT = 0;
DECLARE @IncludedColumns VARCHAR(50) = 'DoesntMatter';

DECLARE @ExpectedMessage NVARCHAR(MAX) = N'Procedure or function ''sp_estindex'' expects parameter ''@TableName'', which was not supplied.';
DECLARE @ExpectedSeverity TINYINT = 16;
DECLARE @ExpectedState TINYINT = 4;
DECLARE @ExpectedErrorNumber INT = 201;

--Assert
EXEC [tSQLt].[ExpectException] @ExpectedMessage = @ExpectedMessage, @ExpectedSeverity = @ExpectedSeverity, @ExpectedState = @ExpectedState, @ExpectedErrorNumber = 201
EXEC [dbo].[sp_estindex] @IncludedColumns = @IncludedColumns, @Verbose = @Verbose;

END;
GO

/*
test failure with invalid @IndexColumns
*/
CREATE PROCEDURE [sp_estindex].[test sp fails with invalid @IndexColumns]
AS
BEGIN;

--Build
DECLARE @Verbose BIT = 0;
DECLARE @IndexColumns VARCHAR(50) = 'BadColumnName';
DECLARE @SchemaName SYSNAME = 'tSQLt';
DECLARE @TableName SYSNAME = 'CaptureOutputLog';

DECLARE @ExpectedMessage NVARCHAR(MAX) = CONCAT('[sp_estindex]: Column name ''', @IndexColumns, ''' does not exist in the target table or view.');
DECLARE @ExpectedSeverity TINYINT = 16;
DECLARE @ExpectedState TINYINT = 1;
DECLARE @ExpectedErrorNumber INT = 50000;

--Assert
EXEC [tSQLt].[ExpectException] @ExpectedMessage = @ExpectedMessage, @ExpectedSeverity = @ExpectedSeverity, @ExpectedState = @ExpectedState, @ExpectedErrorNumber = @ExpectedErrorNumber
EXEC [dbo].[sp_estindex]  @IndexColumns = @IndexColumns, @TableName = @TableName, @SchemaName = @SchemaName, @Verbose = @Verbose;

END;
GO


/*
test failure with invalid @Database
*/
CREATE PROCEDURE [sp_estindex].[test sp fails with invalid @Database]
AS
BEGIN;

--Build
DECLARE @Verbose BIT = 0;
DECLARE @IndexColumns VARCHAR(50) = 'BadColumnName';
DECLARE @SchemaName SYSNAME = 'tSQLt';
DECLARE @TableName SYSNAME = 'CaptureOutputLog';
DECLARE @DatabaseName SYSNAME = 'IDontExist';

DECLARE @ExpectedMessage NVARCHAR(MAX) = '[sp_estindex]: Database does not exist.';
DECLARE @ExpectedSeverity TINYINT = 16;
DECLARE @ExpectedState TINYINT = 1;
DECLARE @ExpectedErrorNumber INT = 50000;

--Assert
EXEC [tSQLt].[ExpectException] @ExpectedMessage = @ExpectedMessage, @ExpectedSeverity = @ExpectedSeverity, @ExpectedState = @ExpectedState, @ExpectedErrorNumber = @ExpectedErrorNumber
EXEC [dbo].[sp_estindex]  @IndexColumns = @IndexColumns, @TableName = @TableName, @SchemaName = @SchemaName, @Verbose = @Verbose, @DatabaseName = @DatabaseName;

END;
GO

/*
test failure with invalid @FillFactor
*/
CREATE PROCEDURE [sp_estindex].[test sp fails with invalid @FillFactor]
AS
BEGIN;

--Build
DECLARE @Verbose BIT = 0;
DECLARE @IndexColumns VARCHAR(50) = 'BadColumnName';
DECLARE @SchemaName SYSNAME = 'tSQLt';
DECLARE @TableName SYSNAME = 'CaptureOutputLog';
DECLARE @DatabaseName SYSNAME = 'IDontExist';
DECLARE @FillFactor TINYINT = 101;

DECLARE @ExpectedMessage NVARCHAR(MAX) = '[sp_estindex]: Fill factor must be between 1 and 100.';
DECLARE @ExpectedSeverity TINYINT = 16;
DECLARE @ExpectedState TINYINT = 1;
DECLARE @ExpectedErrorNumber INT = 50000;

--Assert
EXEC [tSQLt].[ExpectException] @ExpectedMessage = @ExpectedMessage, @ExpectedSeverity = @ExpectedSeverity, @ExpectedState = @ExpectedState, @ExpectedErrorNumber = @ExpectedErrorNumber
EXEC [dbo].[sp_estindex]  @IndexColumns = @IndexColumns, @TableName = @TableName, @SchemaName = @SchemaName, @Verbose = @Verbose, @FillFactor = @FillFactor;

END;
GO

/************************************
End sp_estindex tests
*************************************/

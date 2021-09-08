SET NOCOUNT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;

/************************************/
/* Begin sp_estindex tests          */
/************************************/

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
EXEC tSQLt.AssertObjectExists @objectName = @ObjectName
    ,@message = @Message;

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
EXEC [tSQLt].[ExpectNoException];
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
DECLARE @TableName SYSNAME = 'CaptureOutputLog';
DECLARE @IndexColumns NVARCHAR(MAX) = N'Id';
DECLARE @SchemaName SYSNAME = 'tSQLt';
DECLARE @command NVARCHAR(MAX) = CONCAT('EXEC [dbo].[sp_estindex] @IsUnique = ',@IsUnique, ', @TableName =''', @TableName, ''', @IndexColumns =''', @IndexColumns, ''', @SchemaName = ''', @SchemaName, ''', @Verbose =', @Verbose, ';');

--Assert
EXEC [tSQLt].[ExpectNoException];
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
EXEC [tSQLt].[ExpectNoException];
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
DECLARE @FillFactor TINYINT = 50;
DECLARE @command NVARCHAR(MAX) = CONCAT('EXEC [dbo].[sp_estindex] @FillFactor = ',@FillFactor ,
    ', @TableName = ''CaptureOutputLog'', @IndexColumns = ''Id'', @SchemaName = ''tSQLt'', @Verbose =', @Verbose, ';');

--Assert
EXEC [tSQLt].[ExpectNoException];
EXEC [tSQLt].[SuppressOutput] @command = @command;

END;
GO

/*
test success with included columns
*/
CREATE PROCEDURE [sp_estindex].[test sp succeeds on included columns]
AS
BEGIN;

--Build
DECLARE @Verbose BIT = 1;
DECLARE @IncludeColumns VARCHAR(50) = 'OutputText';
DECLARE @IndexColumns VARCHAR(50) = 'Id';
DECLARE @SchemaName SYSNAME = 'tSQLt';
DECLARE @TableName SYSNAME = 'CaptureOutputLog';

DECLARE @command NVARCHAR(MAX) = CONCAT('EXEC [dbo].[sp_estindex] @IncludeColumns = ''',@IncludeColumns ,
    ''', @TableName = ''', @TableName, ''', @IndexColumns = ''',@IndexColumns, ''', @SchemaName = ''', @SchemaName, ''', @Verbose =', @Verbose, ';');

--Assert
EXEC [tSQLt].[ExpectNoException];
EXEC [tSQLt].[SuppressOutput] @command = @command;

END;
GO

/*
test success with unique index on heap
*/
CREATE PROCEDURE [sp_estindex].[test sp succeeds on unique index on heap]
AS
BEGIN;

--Build
DECLARE @Verbose BIT = 1;
DECLARE @IndexColumns VARCHAR(50) = 'ID';
DECLARE @TableName SYSNAME = 'TempHeap';
DECLARE @IsUnique BIT = 1;
DECLARE @DatabaseName SYSNAME = DB_NAME();
DECLARE @command NVARCHAR(MAX) = CONCAT('EXEC [dbo].[sp_estindex] @DatabaseName =''', @DatabaseName, ''', @TableName = ''', @TableName, ''', @IndexColumns = ''',@IndexColumns, ''', @IsUnique =', @IsUnique, ', @Verbose =', @Verbose, ';');
DECLARE @ResultSetNumber TINYINT = 5; --5 = estimated index size
DECLARE @FailMessage NVARCHAR(MAX) = N'Index size estimation failed - not > 0.';

--Populate table to build index for
IF OBJECT_ID('tsql.dbo.TempHeap') IS NOT NULL
BEGIN
    DROP TABLE dbo.TempHeap;
END

CREATE TABLE TempHeap(ID INT);

WITH Nums(Number) AS
(SELECT 1 AS [Number]
 UNION ALL
 SELECT Number+1 FROM [Nums] WHERE [Number] < 1000
)
INSERT INTO dbo.TempHeap(ID)
SELECT [Number] FROM [Nums] OPTION(MAXRECURSION 1000);

--Create empty table for result set
CREATE TABLE #Result (
    [Est. KB] DECIMAL(10,3)
    ,[Est. MB] DECIMAL(10,3)
    ,[Est. GB] DECIMAL(10,3)
);

--Assert
EXEC [tSQLt].[ExpectNoException];
INSERT INTO #Result
EXEC [tSQLt].[ResultSetFilter] @ResultSetNumber
    ,@command = @command;

DECLARE @EstKB DECIMAL(10,3) = (SELECT [Est. KB] FROM #Result);

IF (@EstKB IS NULL) OR (@EstKB <= 0.0)
    BEGIN;
        EXEC [tSQLt].[Fail] @FailMessage, @EstKb;
    END;

--Teardown
DROP TABLE dbo.TempHeap;
DROP TABLE #Result;

END;
GO

/*
test success with non-unique index on heap
*/
CREATE PROCEDURE [sp_estindex].[test sp succeeds on non-unique index on heap]
AS
BEGIN;

--Build
DECLARE @Verbose BIT = 1;
DECLARE @IndexColumns VARCHAR(50) = 'ID';
DECLARE @TableName SYSNAME = 'TempHeap';
DECLARE @IsUnique BIT = 0;
DECLARE @DatabaseName SYSNAME = DB_NAME();
DECLARE @command NVARCHAR(MAX) = CONCAT('EXEC [dbo].[sp_estindex] @DatabaseName =''', @DatabaseName, ''', @TableName = ''', @TableName, ''', @IndexColumns = ''',@IndexColumns, ''', @IsUnique =', @IsUnique, ', @Verbose =', @Verbose, ';');
DECLARE @ResultSetNumber TINYINT = 5; --5 = estimated index size
DECLARE @FailMessage NVARCHAR(MAX) = N'Index size estimation failed - not > 0.';

--Populate table to build index for
IF OBJECT_ID('dbo.TempHeap') IS NOT NULL
BEGIN
    DROP TABLE dbo.TempHeap;
END

CREATE TABLE dbo.TempHeap(
ID INT);

WITH Nums(Number) AS
(SELECT 1 AS [Number]
 UNION ALL
 SELECT Number+1 FROM [Nums] WHERE [Number] < 1000
)
INSERT INTO dbo.TempHeap(ID)
SELECT [Number] FROM [Nums] OPTION(MAXRECURSION 1000);

--Create empty table for result set
CREATE TABLE #Result (
    [Est. KB] DECIMAL(10,3)
    ,[Est. MB] DECIMAL(10,3)
    ,[Est. GB] DECIMAL(10,3)
);

--Assert
EXEC [tSQLt].[ExpectNoException];
INSERT INTO #Result
EXEC [tSQLt].[ResultSetFilter] @ResultSetNumber, @command = @command;

DECLARE @EstKB DECIMAL(10,3) = (SELECT [Est. KB] FROM #Result);

IF (@EstKB IS NULL) OR (@EstKB <= 0.0)
    BEGIN;
        EXEC [tSQLt].[Fail] @FailMessage, @EstKb;
    END;

--Teardown
DROP TABLE dbo.TempHeap;
DROP TABLE #Result;

END;
GO

/*
test success with unique index on clustered
*/
CREATE PROCEDURE [sp_estindex].[test sp succeeds on unique index on clustered]
AS
BEGIN;

--Build
DECLARE @Verbose BIT = 1;
DECLARE @IndexColumns VARCHAR(50) = 'ID';
DECLARE @TableName SYSNAME = 'TempClustered';
DECLARE @DatabaseName SYSNAME = DB_NAME();
DECLARE @IsUnique BIT = 1;
DECLARE @command NVARCHAR(MAX) = CONCAT('EXEC [dbo].[sp_estindex] @DatabaseName =''', @DatabaseName, ''', @TableName = ''', @TableName, ''', @IsUnique =', @IsUnique, ', @IndexColumns = ''',@IndexColumns, ''', @Verbose =', @Verbose, ';');
DECLARE @ResultSetNumber TINYINT = 5; --5 = estimated index size
DECLARE @FailMessage NVARCHAR(MAX) = N'Index size estimation failed - not > 0.';

IF OBJECT_ID('dbo.TempClustered') IS NOT NULL
BEGIN
    DROP TABLE dbo.TempClustered;
END

--Populate table to build index for
CREATE TABLE dbo.TempClustered(ID INT);

CREATE CLUSTERED INDEX cdx_temporary ON dbo.TempClustered(ID);


;WITH Nums(Number) AS
(SELECT 1 AS [Number]
 UNION ALL
 SELECT Number+1 FROM [Nums] WHERE [Number]<1000
)
INSERT INTO dbo.TempClustered(ID)
SELECT [Number] FROM [Nums] OPTION(maxrecursion 1000);

--Create empty table for result set
CREATE TABLE #Result (
    [Est. KB] DECIMAL(10,3)
    ,[Est. MB] DECIMAL(10,3)
    ,[Est. GB] DECIMAL(10,3)
);


--Assert
EXEC [tSQLt].[ExpectNoException];
INSERT INTO #Result
EXEC [tSQLt].[ResultSetFilter] @ResultSetNumber
    ,@command = @command;

DECLARE @EstKB DECIMAL(10,3) = (SELECT [Est. KB] FROM #Result);

IF (@EstKB IS NULL) OR (@EstKB <= 0.0)
    BEGIN;
        EXEC [tSQLt].[Fail] @FailMessage, @EstKb;
    END;

--Teardown
DROP TABLE dbo.TempClustered;
DROP TABLE #Result;

END;
GO

/*
test success with multi-leaf index
*/
CREATE PROCEDURE [sp_estindex].[test sp succeeds on multi-leaf index]
AS
BEGIN;

--Build
DECLARE @Verbose BIT = 1;
DECLARE @IndexColumns VARCHAR(50) = 'ID';
DECLARE @TableName SYSNAME = 'TempHeap';
DECLARE @DatabaseName SYSNAME = DB_NAME();
DECLARE @IsUnique BIT = 1;
DECLARE @command NVARCHAR(MAX) = CONCAT('EXEC [dbo].[sp_estindex] @DatabaseName =''', @DatabaseName, ''', @TableName = ''', @TableName, ''', @IsUnique =', @IsUnique, ', @IndexColumns = ''',@IndexColumns, ''', @Verbose =', @Verbose, ';');
DECLARE @ResultSetNumber TINYINT = 5; --5 = estimated index size
DECLARE @FailMessage NVARCHAR(MAX) = N'Index size estimation failed - not > 0.';

IF OBJECT_ID('dbo.TempHeap') IS NOT NULL
BEGIN
    DROP TABLE dbo.TempHeap;
END

--Populate table
CREATE TABLE dbo.TempHeap(
ID INT);

;WITH Nums(Number) AS
(SELECT 1 AS [Number]
 UNION ALL
 SELECT Number+1 FROM [Nums] WHERE [Number]<10000
)
INSERT INTO dbo.TempHeap(ID)
SELECT [Number] FROM [Nums] OPTION(maxrecursion 10000);

--Create empty table for result set
CREATE TABLE #Result (
    [Est. KB] DECIMAL(10,3)
    ,[Est. MB] DECIMAL(10,3)
    ,[Est. GB] DECIMAL(10,3)
);

--Assert
EXEC [tSQLt].[ExpectNoException];
INSERT INTO #Result
EXEC [tSQLt].[ResultSetFilter] @ResultSetNumber
    ,@command = @command;

DECLARE @EstKB DECIMAL(10,3) = (SELECT [Est. KB] FROM #Result);

IF (@EstKB IS NULL) OR (@EstKB <= 0.0)
    BEGIN;
        EXEC [tSQLt].[Fail] @FailMessage, @EstKb;
    END;

--Teardown
DROP TABLE dbo.TempHeap;
DROP TABLE #Result;

END;
GO

/*
test success with non-unique index on clustered
*/
CREATE PROCEDURE [sp_estindex].[test sp succeeds on non-unique index on clustered]
AS
BEGIN;

--Build
DECLARE @Verbose BIT = 1;
DECLARE @IndexColumns VARCHAR(50) = 'ID';
DECLARE @TableName SYSNAME = 'TempClustered';
DECLARE @DatabaseName SYSNAME = DB_NAME();
DECLARE @IsUnique BIT = 0;
DECLARE @command NVARCHAR(MAX) = CONCAT('EXEC [dbo].[sp_estindex] @DatabaseName =''', @DatabaseName, ''', @TableName = ''', @TableName, ''', @IsUnique =', @IsUnique, ', @IndexColumns = ''',@IndexColumns, ''', @Verbose =', @Verbose, ';');
DECLARE @ResultSetNumber TINYINT = 5; --5 = estimated index size
DECLARE @FailMessage NVARCHAR(MAX) = N'Index size estimation failed - not > 0.';

IF OBJECT_ID('dbo.TempClustered') IS NOT NULL
BEGIN
    DROP TABLE dbo.TempClustered;
END

--Populate table to build index for
CREATE TABLE dbo.TempClustered(
ID INT);


;WITH Nums(Number) AS
(SELECT 1 AS [Number]
 UNION ALL
 SELECT Number+1 FROM [Nums] WHERE [Number]<1000
)
INSERT INTO dbo.TempClustered(ID)
SELECT [Number] FROM [Nums] OPTION(maxrecursion 1000);

CREATE CLUSTERED INDEX cdx_temporary ON dbo.TempClustered(ID);

--Create empty table for result set
CREATE TABLE #Result (
    [Est. KB] DECIMAL(10,3)
    ,[Est. MB] DECIMAL(10,3)
    ,[Est. GB] DECIMAL(10,3)
);

--Assert
EXEC [tSQLt].[ExpectNoException];
INSERT INTO #Result
EXEC [tSQLt].[ResultSetFilter] @ResultSetNumber
    ,@command = @command;

DECLARE @EstKB DECIMAL(10,3) = (SELECT [Est. KB] FROM #Result);

IF (@EstKB IS NULL) OR (@EstKB <= 0.0)
    BEGIN;
        EXEC [tSQLt].[Fail] @FailMessage, @EstKb;
    END;

--Teardown
DROP TABLE dbo.TempClustered;
DROP TABLE #Result;

END;
GO

/*
test success with existing ##TempMissingIndex
*/
/*
CREATE PROCEDURE [sp_estindex].[test sp succeeds on existing ##TempMissingIndex]
AS
BEGIN;

--Build
DECLARE @Verbose BIT = 1;
DECLARE @IncludeColumns VARCHAR(50) = 'OutputText';
DECLARE @IndexColumns VARCHAR(50) = 'Id';
DECLARE @SchemaName SYSNAME = 'tSQLt';
DECLARE @TableName SYSNAME = 'CaptureOutputLog';

SELECT 1 AS [one]
INTO ##TempMissingIndex;

DECLARE @command NVARCHAR(MAX) = CONCAT('EXEC [dbo].[sp_estindex] @TableName = ''', @TableName, ''', @IndexColumns = ''',@IndexColumns, ''', @SchemaName = ''', @SchemaName, ''', @Verbose =', @Verbose, ';');

--Assert
EXEC [tSQLt].[ExpectNoException];
EXEC [tSQLt].[SuppressOutput] @command = @command;

END;
GO
*/
/*
test success with nullable columns
*/
CREATE PROCEDURE [sp_estindex].[test sp succeeds on nullable columns]
AS
BEGIN;

--Build
DECLARE @Verbose BIT = 0;
DECLARE @IndexColumns VARCHAR(50) = 'name';
DECLARE @SchemaName SYSNAME = 'tSQLt';
DECLARE @TableName SYSNAME = 'Private_AssertEqualsTableSchema_Actual';

DECLARE @command NVARCHAR(MAX) = CONCAT('EXEC [dbo].[sp_estindex] @TableName = ''', @TableName, ''', @IndexColumns = ''',@IndexColumns, ''', @SchemaName = ''', @SchemaName, ''', @Verbose =', @Verbose, ';');

--Assert
EXEC [tSQLt].[ExpectNoException];
EXEC [tSQLt].[SuppressOutput] @command = @command;

END;
GO

/*
test success with variable len columns
*/
CREATE PROCEDURE [sp_estindex].[test sp succeeds on variable len columns]
AS
BEGIN;

--Build
DECLARE @Verbose BIT = 1;
DECLARE @IndexColumns VARCHAR(50) = 'ID';
DECLARE @TableName SYSNAME = 'TempHeap';
DECLARE @DatabaseName SYSNAME = DB_NAME();
DECLARE @command NVARCHAR(MAX) = CONCAT('EXEC [dbo].[sp_estindex] @DatabaseName =''', @DatabaseName, ''', @TableName = ''', @TableName, ''', @IndexColumns = ''',@IndexColumns, ''', @Verbose =', @Verbose, ';');

IF OBJECT_ID('dbo.TempHeap') IS NOT NULL
    BEGIN;
        DROP TABLE dbo.TempHeap;
    END

--Create table
CREATE TABLE dbo.TempHeap(ID NVARCHAR(200));

--Assert
EXEC [tSQLt].[ExpectNoException];
EXEC [tSQLt].[SuppressOutput] @command = @command;

--Teardown
DROP TABLE dbo.TempHeap;

END;
GO

/*
test success with verbose mode
*/
CREATE PROCEDURE [sp_estindex].[test sp succeeds on verbose mode]
AS
BEGIN;

--Build
DECLARE @Verbose BIT = 1;
DECLARE @IndexColumns VARCHAR(50) = 'name';
DECLARE @SchemaName SYSNAME = 'tSQLt';
DECLARE @TableName SYSNAME = 'Private_AssertEqualsTableSchema_Actual';

DECLARE @command NVARCHAR(MAX) = CONCAT('EXEC [dbo].[sp_estindex] @TableName = ''', @TableName, ''', @IndexColumns = ''',@IndexColumns, ''', @SchemaName = ''', @SchemaName, ''', @Verbose =', @Verbose, ';');

--Assert
EXEC [tSQLt].[ExpectNoException];
EXEC [tSQLt].[SuppressOutput] @command = @command;

END;
GO

/*
test success with variable len include columns
*/
CREATE PROCEDURE [sp_estindex].[test sp succeeds on variable len include columns]
AS
BEGIN;

--Build
DECLARE @Verbose BIT = 1;
DECLARE @IndexColumns VARCHAR(50) = 'ID';
DECLARE @IncludeColumns VARCHAR(100) = 'Description';
DECLARE @TableName SYSNAME = 'TempHeap';
DECLARE @DatabaseName SYSNAME = DB_NAME();
DECLARE @command NVARCHAR(MAX) = CONCAT('EXEC [dbo].[sp_estindex] @DatabaseName =''', @DatabaseName,
                                                            ''', @TableName = ''', @TableName,
                                                            ''', @IndexColumns = ''',@IndexColumns,
                                                            ''', @IncludeColumns = ''',@IncludeColumns,
                                                            ''', @Verbose =', @Verbose, ';');

IF OBJECT_ID('dbo.TempHeap') IS NOT NULL
    BEGIN;
        DROP TABLE dbo.TempHeap;
    END

--Create table
CREATE TABLE dbo.TempHeap(ID INT, [Description] NVARCHAR(200));

--Assert
EXEC [tSQLt].[ExpectNoException];
EXEC [tSQLt].[SuppressOutput] @command = @command;

--Teardown
DROP TABLE dbo.TempHeap;

END;
GO


/*
test success without @SchemaName
*/
CREATE PROCEDURE [sp_estindex].[test sp succeeds on no @SchemaName]
AS
BEGIN;

--Build
DECLARE @Verbose BIT = 1;
DECLARE @IndexColumns VARCHAR(50) = 'ID';
DECLARE @TableName SYSNAME = 'TempHeap';
DECLARE @DatabaseName SYSNAME = DB_NAME();
DECLARE @command NVARCHAR(MAX) = CONCAT('EXEC [dbo].[sp_estindex] @DatabaseName =''', @DatabaseName, ''', @TableName = ''', @TableName, ''', @IndexColumns = ''',@IndexColumns, ''', @Verbose =', @Verbose, ';');

IF OBJECT_ID('dbo.TempHeap') IS NOT NULL
    BEGIN;
        DROP TABLE dbo.TempHeap;
    END

--Create table
CREATE TABLE dbo.TempHeap(ID INT);

--Assert
EXEC [tSQLt].[ExpectNoException];
EXEC [tSQLt].[SuppressOutput] @command = @command;

--Teardown
DROP TABLE dbo.TempHeap;

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
EXEC [tSQLt].[ExpectException] @ExpectedMessage = @ExpectedMessage
    ,@ExpectedSeverity = @ExpectedSeverity
    ,@ExpectedState = @ExpectedState
    ,@ExpectedErrorNumber = @ExpectedErrorNumber;
EXEC [dbo].[sp_estindex] @SqlMajorVersion = @version
    ,@TableName = @TableName
    ,@IndexColumns = @IndexColumns
    ,@Verbose = @Verbose;

END;
GO

/*
test failure with no @IndexColumns
*/
CREATE PROCEDURE [sp_estindex].[test sp fails on no @IndexColumns]
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
EXEC [tSQLt].[ExpectException] @ExpectedMessage = @ExpectedMessage
    ,@ExpectedSeverity = @ExpectedSeverity
    ,@ExpectedState = @ExpectedState
    ,@ExpectedErrorNumber = @ExpectedErrorNumber;
EXEC [dbo].[sp_estindex] @TableName = @TableName
    ,@Verbose = @Verbose;

END;
GO

/*
test failure with no @TableName
*/
CREATE PROCEDURE [sp_estindex].[test sp fails on no @TableName]
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
EXEC [tSQLt].[ExpectException] @ExpectedMessage = @ExpectedMessage
    ,@ExpectedSeverity = @ExpectedSeverity
    ,@ExpectedState = @ExpectedState
    ,@ExpectedErrorNumber = @ExpectedErrorNumber;
EXEC [dbo].[sp_estindex] @IncludedColumns = @IncludedColumns
    ,@Verbose = @Verbose;

END;
GO

/*
test failure with invalid @IndexColumns
*/
CREATE PROCEDURE [sp_estindex].[test sp fails on invalid @IndexColumns]
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
EXEC [tSQLt].[ExpectException] @ExpectedMessage = @ExpectedMessage
    ,@ExpectedSeverity = @ExpectedSeverity
    ,@ExpectedState = @ExpectedState
    ,@ExpectedErrorNumber = @ExpectedErrorNumber;
EXEC [dbo].[sp_estindex]  @IndexColumns = @IndexColumns
    ,@TableName = @TableName
    ,@SchemaName = @SchemaName
    ,@Verbose = @Verbose;

END;
GO


/*
test failure with invalid @Database
*/
CREATE PROCEDURE [sp_estindex].[test sp fails on invalid @Database]
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
EXEC [tSQLt].[ExpectException] @ExpectedMessage = @ExpectedMessage
    ,@ExpectedSeverity = @ExpectedSeverity
    ,@ExpectedState = @ExpectedState
    ,@ExpectedErrorNumber = @ExpectedErrorNumber;
EXEC [dbo].[sp_estindex] @IndexColumns = @IndexColumns
    ,@TableName = @TableName
    ,@SchemaName = @SchemaName
    ,@Verbose = @Verbose
    ,@DatabaseName = @DatabaseName;

END;
GO

/*
test failure with invalid @FillFactor
*/
CREATE PROCEDURE [sp_estindex].[test sp fails on invalid @FillFactor]
AS
BEGIN;

--Build
DECLARE @Verbose BIT = 0;
DECLARE @IndexColumns VARCHAR(50) = 'BadColumnName';
DECLARE @SchemaName SYSNAME = 'tSQLt';
DECLARE @TableName SYSNAME = 'CaptureOutputLog';
DECLARE @FillFactor TINYINT = 101;

DECLARE @ExpectedMessage NVARCHAR(MAX) = '[sp_estindex]: Fill factor must be between 1 and 100.';
DECLARE @ExpectedSeverity TINYINT = 16;
DECLARE @ExpectedState TINYINT = 1;
DECLARE @ExpectedErrorNumber INT = 50000;

--Assert
EXEC [tSQLt].[ExpectException] @ExpectedMessage = @ExpectedMessage
    ,@ExpectedSeverity = @ExpectedSeverity
    ,@ExpectedState = @ExpectedState
    ,@ExpectedErrorNumber = @ExpectedErrorNumber;
EXEC [dbo].[sp_estindex] @IndexColumns = @IndexColumns
    ,@TableName = @TableName
    ,@SchemaName = @SchemaName
    ,@Verbose = @Verbose
    ,@FillFactor = @FillFactor;

END;
GO

/*
test failure with invalid @VarcharFillPercent
*/
CREATE PROCEDURE [sp_estindex].[test sp fails on invalid @VarcharFillPercent]
AS
BEGIN;

--Build
DECLARE @Verbose BIT = 0;
DECLARE @IndexColumns VARCHAR(50) = 'BadColumnName';
DECLARE @SchemaName SYSNAME = 'tSQLt';
DECLARE @TableName SYSNAME = 'CaptureOutputLog';
DECLARE @VarcharFillPercent TINYINT = 101;

DECLARE @ExpectedMessage NVARCHAR(MAX) = '[sp_estindex]: Varchar fill percent must be between 1 and 100.';
DECLARE @ExpectedSeverity TINYINT = 16;
DECLARE @ExpectedState TINYINT = 1;
DECLARE @ExpectedErrorNumber INT = 50000;

--Assert
EXEC [tSQLt].[ExpectException] @ExpectedMessage = @ExpectedMessage
    ,@ExpectedSeverity = @ExpectedSeverity
    ,@ExpectedState = @ExpectedState
    ,@ExpectedErrorNumber = @ExpectedErrorNumber;
EXEC [dbo].[sp_estindex] @IndexColumns = @IndexColumns
    ,@TableName = @TableName
    ,@SchemaName = @SchemaName
    ,@Verbose = @Verbose
    ,@VarcharFillPercent = @VarcharFillPercent;

END;
GO

/*
test failure on @Filter missing WHERE
*/
CREATE PROCEDURE [sp_estindex].[test sp fails on @Filter missing WHERE]
AS
BEGIN;

--Build
DECLARE @Verbose BIT = 0;
DECLARE @TableName VARCHAR(50) = 'DoesntMatter';
DECLARE @IndexColumns VARCHAR(50) = 'AlsoDoesntMatter';
DECLARE @Filter VARCHAR(50) = 'SomeCol = 2';

DECLARE @ExpectedMessage NVARCHAR(MAX) = '[sp_estindex]: Filter must start with ''WHERE''.';
DECLARE @ExpectedSeverity TINYINT = 16;
DECLARE @ExpectedState TINYINT = 1;
DECLARE @ExpectedErrorNumber INT = 50000;

--Assert
EXEC [tSQLt].[ExpectException] @ExpectedMessage = @ExpectedMessage
    ,@ExpectedSeverity = @ExpectedSeverity
    ,@ExpectedState = @ExpectedState
    ,@ExpectedErrorNumber = @ExpectedErrorNumber;
EXEC [dbo].[sp_estindex] @TableName = @TableName
    ,@IndexColumns = @IndexColumns
    ,@Filter = @Filter
    ,@Verbose = @Verbose;

END;
GO

/************************************
End sp_estindex tests
*************************************/

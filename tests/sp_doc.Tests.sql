SET NOCOUNT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;

/************************************
Begin sp_doc tests
*************************************/

--Clean Class
EXEC [tSQLt].[DropClass] 'sp_doc';
GO

EXEC [tSQLT].[NewTestClass] 'sp_doc';
GO

/* 
=================
Positive Testing
=================
*/

/* test that sp_doc exists */
CREATE PROCEDURE [sp_doc].[test sp succeeds on create]
AS
BEGIN;

DECLARE @ObjectName NVARCHAR(1000) = N'dbo.sp_doc';
DECLARE @ErrorMessage NVARCHAR(MAX) = N'Stored procedure sp_doc does not exist.';

--Assert
EXEC [tSQLt].[AssertObjectExists] @objectName = @objectName, @message = @ErrorMessage;

END;
GO

/* test sp succeeds on valid db */
CREATE PROCEDURE [sp_doc].[test sp succeeds on valid db]
AS
BEGIN;

DECLARE @db SYSNAME = DB_NAME(DB_ID());
DECLARE @command NVARCHAR(MAX) = '[dbo].[sp_doc] @DatabaseName = ' + @db + ';';

--Assert
EXEC [tSQLt].[ExpectNoException];
EXEC sp_executesql @command;
--EXEC [tSQLt].[SuppressOutput] @command = @command;

END;
GO

/* test sp_doc emoji mode doesn't error */
CREATE PROCEDURE [sp_doc].[test sp succeeds in emoji mode]
AS
BEGIN;

DECLARE @db SYSNAME = DB_NAME(DB_ID());
DECLARE @command NVARCHAR(MAX) = '[dbo].[sp_doc] @DatabaseName = ' + @db + ', @Emojis = 1;';

--Assert
EXEC [tSQLt].[ExpectNoException];
EXEC sp_executesql @command;
--EXEC [tSQLt].[SuppressOutput] @command = @command;

END;
GO

/* test sp_doc unlimited stored proc length doesn't error */
CREATE PROCEDURE [sp_doc].[test sp succeeds with unlimited sp output]
AS
BEGIN;

DECLARE @db SYSNAME = DB_NAME(DB_ID());
DECLARE @command NVARCHAR(MAX) = '[dbo].[sp_doc] @DatabaseName = ' + @db + ', @LimitStoredProcLength = 1;';

--Assert
EXEC [tSQLt].[ExpectNoException];
EXEC sp_executesql @command;
--EXEC [tSQLt].[SuppressOutput] @command = @command;

END;
GO

/* test sp_doc succeeds on assume current db if none given */
CREATE PROCEDURE [sp_doc].[test sp succeeds on current db if none given]
AS
BEGIN;

DECLARE @Verbose BIT = 0;
DECLARE @command NVARCHAR(MAX) = CONCAT('[dbo].[sp_doc] @Verbose = ', @Verbose, ';');

--Assert
EXEC [tSQLt].[ExpectNoException];
EXEC sp_executesql @command;
--EXEC [tSQLt].[SuppressOutput] @command = @command;

END;
GO

/* test sp_doc succeeds on supported SQL Server >= v12 */
CREATE PROCEDURE [sp_doc].[test sp succeeds on supported version]
AS
BEGIN;

DECLARE @version TINYINT = 13;
DECLARE @Verbose BIT = 0;
DECLARE @command NVARCHAR(MAX) = CONCAT('[dbo].[sp_doc] @SqlMajorVersion = ', @version, ', @Verbose = ', @Verbose, ';');

--Assert
EXEC [tSQLt].[ExpectNoException];
EXEC sp_executesql @command;
--EXEC [tSQLt].[SuppressOutput] @command = @command;

END;
GO

/* test sp_doc returns correct metadata */
CREATE PROCEDURE [sp_doc].[test sp succeeds on returning desired metadata]
AS
BEGIN;

EXEC tSQLt.AssertResultSetsHaveSameMetaData
    'SELECT CAST(''test'' AS NVARCHAR(MAX)) as [value]',
    'EXEC [dbo].[sp_doc] @Verbose = 0';

END;
GO

/* test sp_doc returns correct minimum rows */
CREATE PROCEDURE [sp_doc].[test sp succeeds on returning minimum rowcount]
AS
BEGIN;

--Rows returned from empty database
DECLARE @TargetRows SMALLINT = 22;
DECLARE @ReturnedRows BIGINT;
DECLARE @FailMessage NVARCHAR(MAX) = N'Minimum number of rows were not returned.';
DECLARE @Verbose BIT = 0;

EXEC [dbo].[sp_doc] @Verbose = @Verbose;
SET @ReturnedRows = @@ROWCOUNT;

IF (@TargetRows > @ReturnedRows)
    BEGIN;
        EXEC [tSQLt].[Fail] @FailMessage, @ReturnedRows;
    END;

END;
GO

/* test sp_doc returns correct Sensitivity Classification */
CREATE PROCEDURE [sp_doc].[test sp returns correct Sensitivity Classification]
AS
BEGIN;

--TODO: Upgrade this to use SKIP functionality when tSQLt is upgraded - https://github.com/LowlyDBA/dba-multitool/issues/165
--Rows returned from empty database
DECLARE @SqlMajorVersion TINYINT;
DECLARE @Verbose BIT = 0;
DECLARE @DatabaseName SYSNAME = 'tSQLt';
DECLARE @Sql NVARCHAR(MAX);
DECLARE @FailMessage NVARCHAR(MAX) = N'Did not find test sensitivity classifications in output.';
DECLARE @Expected NVARCHAR(1000) = N'%Label: Highly Confidential <br /> Type: Financial <br /> Rank: CRITICAL <br />%';

SET @SqlMajorVersion = CAST(SERVERPROPERTY('ProductMajorVersion') AS TINYINT);

IF (@SqlMajorVersion >= 15) 
BEGIN
    --Setup
    IF OBJECT_ID('tempdb..#result') IS NOT NULL 
    BEGIN 
        DROP TABLE #result; 
    END
    CREATE TABLE #result ([markdown] VARCHAR(8000));

    SET @Sql = N'ADD SENSITIVITY CLASSIFICATION TO [tSQLt].[CaptureOutputLog].[OutputText]
    WITH (LABEL=''Highly Confidential'', INFORMATION_TYPE=''Financial'', RANK=CRITICAL)';
    EXEC sp_executesql @Sql;
    
    --Get results
    INSERT INTO #result 
    EXEC sp_doc @DatabaseName = @DatabaseName, @Verbose = @Verbose;
    
    --Assert
    IF NOT EXISTS (SELECT 1 FROM #result WHERE [markdown] LIKE @Expected COLLATE DATABASE_DEFAULT)
    BEGIN
        EXEC [tSQLt].[Fail] @FailMessage;
    END;
END;

-- Succeed if version < 15
EXEC [tSQLt].[ExpectNoException];

END;
GO

/* test sp_doc returns correct table index */
CREATE PROCEDURE [sp_doc].[test sp returns correct table index]
AS
BEGIN

DECLARE @Verbose BIT = 0;
DECLARE @DatabaseName SYSNAME = DB_NAME(DB_ID());
DECLARE @IndexName SYSNAME = 'idx_IndexTest';
DECLARE @TableName SYSNAME = 'IndexTest';
DECLARE @Sql NVARCHAR(MAX);
DECLARE @FailMessage NVARCHAR(1000) = CONCAT('Did not find table index ', QUOTENAME(@IndexName), ' in markdown output.');
DECLARE @Expected NVARCHAR(1000) = N'| idx_IndexTest | nonclustered | \[id] |%';

--Setup
IF OBJECT_ID('tempdb..#result') IS NOT NULL 
BEGIN 
    DROP TABLE #result; 
END
CREATE TABLE #result ([markdown] VARCHAR(8000));

SET @Sql = N'CREATE TABLE [dbo].' + QUOTENAME(@TableName) + '([id] INT);
CREATE NONCLUSTERED INDEX ' + QUOTENAME(@IndexName) + ' ON [dbo].' + QUOTENAME(@TableName) + '([id])';
EXEC sp_executesql @Sql;

--Get results
INSERT INTO #result 
EXEC sp_doc @DatabaseName = @DatabaseName, @Verbose = @Verbose;

--Cleanup
SET @Sql = N'DROP TABLE ' + QUOTENAME(@DatabaseName) + '.[dbo].' + QUOTENAME(@TableName) + ';';
EXEC sp_executesql @Sql;

--Assert
IF NOT EXISTS (SELECT 1 FROM #result WHERE [markdown] LIKE @Expected ESCAPE '\' COLLATE DATABASE_DEFAULT)
    BEGIN
        EXEC tSQLt.Fail @FailMessage;
    END;
END;
GO

/* test sp_doc returns correct view index */
CREATE PROCEDURE [sp_doc].[test sp returns correct view index]
AS
BEGIN

DECLARE @Verbose BIT = 0;
DECLARE @DatabaseName SYSNAME = DB_NAME(DB_ID());
DECLARE @IndexName SYSNAME = 'idx_IndexTest';
DECLARE @ViewName SYSNAME = 'vw_IndexTest';
DECLARE @TableName SYSNAME = 'IndexTest';
DECLARE @Sql NVARCHAR(MAX);
DECLARE @FailMessage NVARCHAR(1000) = CONCAT('Did not find view index ', QUOTENAME(@IndexName), ' in markdown output.');

DECLARE @Expected NVARCHAR(1000) = N'| idx_IndexTest | clustered | \[id] |%';

--Setup
IF OBJECT_ID('tempdb..#result') IS NOT NULL 
BEGIN 
    DROP TABLE #result; 
END
CREATE TABLE #result ([markdown] VARCHAR(8000));

SET @Sql = N'CREATE TABLE [dbo].' + QUOTENAME(@TableName) + '([id] INT);';
EXEC sp_executesql @Sql;
SET @Sql = N'CREATE VIEW [dbo].' + QUOTENAME(@ViewName) + ' WITH SCHEMABINDING AS SELECT [id] FROM [dbo].' + QUOTENAME(@TableName) + ';';
EXEC sp_executesql @Sql;
SET @Sql = N'CREATE UNIQUE CLUSTERED INDEX ' + QUOTENAME(@IndexName) + ' ON [dbo].' + QUOTENAME(@ViewName) + ' ([id]);';
EXEC sp_executesql @Sql;

--Get results
INSERT INTO #result 
EXEC sp_doc @DatabaseName = @DatabaseName, @Verbose = @Verbose;

--Cleanup
SET @Sql = N'DROP VIEW [dbo].' + QUOTENAME(@ViewName) + ';
DROP TABLE ' + QUOTENAME(@DatabaseName) + '.[dbo].' + QUOTENAME(@TableName) + ';';
EXEC sp_executesql @Sql;

--Assert
IF NOT EXISTS (SELECT 1 FROM #result WHERE [markdown] LIKE @Expected ESCAPE '\' COLLATE DATABASE_DEFAULT)
    BEGIN
        EXEC tSQLt.Fail @FailMessage;
    END;
END;
GO

/*
=================
Negative Testing
=================
*/

/* test sp_doc errors on invalid db */
CREATE PROCEDURE [sp_doc].[test sp fails on invalid db]
AS
BEGIN;

DECLARE @DatabaseName SYSNAME = 'StarshipVoyager';
DECLARE @ExpectedMessage NVARCHAR(MAX) = N'Database not available.';

--Assert
EXEC [tSQLt].[ExpectException] @ExpectedMessage = @ExpectedMessage;
EXEC [dbo].[sp_doc] @DatabaseName = @DatabaseName;

END;
GO

/* test sp_doc fails on unsupported SQL Server < v12 */
CREATE PROCEDURE [sp_doc].[test sp fails on unsupported version]
AS
BEGIN;

DECLARE @version TINYINT = 10;
DECLARE @ExpectedMessage NVARCHAR(MAX) = N'SQL Server versions below 2012 are not supported, sorry!';

--Assert
EXEC [tSQLt].[ExpectException] @ExpectedMessage = @ExpectedMessage;
EXEC [dbo].[sp_doc] @SqlMajorVersion = @version;

END;
GO

/************************************
End sp_doc tests
*************************************/

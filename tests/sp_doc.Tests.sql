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
======================
Test Prep
======================
*/

/*
Perform external test setup due to strange locking behavior
with 1st time adds for data sensitivity classifications
for [test sp returns correct Sensitivity Classification]
and later tests that rely on the classification table column existing
*/

DECLARE @SqlMajorVersion TINYINT = CAST(SERVERPROPERTY('ProductMajorVersion') AS TINYINT);
DECLARE @DatabaseName SYSNAME = DB_NAME(DB_ID());
DECLARE @Sql NVARCHAR(MAX);

-- Exclude SQL 2017 since sensitivity classification is half-baked in that version
IF EXISTS (SELECT 1 FROM [sys].[system_views] WHERE [name] = 'sensitivity_classifications') AND (@SqlMajorVersion <> 14)
    BEGIN;
        SET @Sql = N'ADD SENSITIVITY CLASSIFICATION TO [tsqlt].[CaptureOutputLog].[OutputText]
        WITH (LABEL=''Highly Confidential'', INFORMATION_TYPE=''Financial'', RANK=CRITICAL);';
        EXEC sp_executesql @Sql;
    END;
GO

-- Give Azure SQL Extra time to apply classification
-- IF (@@VERSION LIKE 'Microsoft SQL Azure%')
--     BEGIN;
--         WAITFOR DELAY '00:00:10';
--     END;
-- GO

/*
=================
Positive Testing
=================
*/

/* test that sp_doc exists */
CREATE PROCEDURE [sp_doc].[test sp succeeds on create]
AS
BEGIN
SET NOCOUNT ON;

DECLARE @ObjectName NVARCHAR(1000) = N'dbo.sp_doc';
DECLARE @ErrorMessage NVARCHAR(MAX) = N'Stored procedure sp_doc does not exist.';

--Assert
EXEC [tSQLt].[AssertObjectExists] @objectName = @objectName, @message = @ErrorMessage;

END;
GO

/* test sp succeeds on valid db */
CREATE PROCEDURE [sp_doc].[test sp succeeds on valid db]
AS
BEGIN
SET NOCOUNT ON;

DECLARE @db SYSNAME = DB_NAME(DB_ID());
DECLARE @command NVARCHAR(MAX) = '[dbo].[sp_doc] @DatabaseName = ' + @db + ';';

--Assert
EXEC [tSQLt].[ExpectNoException];
EXEC sp_executesql @command;
--EXEC [tSQLt].[SuppressOutput] @command = @command;

END;
GO

/* test sp_doc emoji mode doesn't error */
CREATE PROCEDURE [sp_doc].[test sp succeeds on emoji mode]
AS
BEGIN
SET NOCOUNT ON;

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
BEGIN
SET NOCOUNT ON;

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
BEGIN
SET NOCOUNT ON;

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
BEGIN
SET NOCOUNT ON;

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
BEGIN
SET NOCOUNT ON;

EXEC tSQLt.AssertResultSetsHaveSameMetaData
    'SELECT CAST(''test'' AS NVARCHAR(MAX)) as [value]',
    'EXEC [dbo].[sp_doc] @Verbose = 0';

END;
GO

/* test sp_doc returns correct minimum rows */
CREATE PROCEDURE [sp_doc].[test sp succeeds on returning minimum rowcount]
AS
BEGIN
SET NOCOUNT ON;

--Rows returned from empty database
DECLARE @TargetRows SMALLINT = 22;
DECLARE @ReturnedRows BIGINT;
DECLARE @FailMessage NVARCHAR(MAX) = N'Minimum number of rows were not returned. Rows returned: ';
DECLARE @Verbose BIT = 0;

EXEC [dbo].[sp_doc] @Verbose = @Verbose;
SET @ReturnedRows = @@ROWCOUNT;

IF (@TargetRows > @ReturnedRows)
    BEGIN;
        EXEC [tSQLt].[Fail] @FailMessage, @ReturnedRows;
    END;

END;
GO


/* test sp_doc returns correct Sensitivity Classification
NOTE: Requires test prep at top of this file to run */
CREATE PROCEDURE [sp_doc].[test sp returns correct Sensitivity Classification]
AS
BEGIN
SET NOCOUNT ON;

DECLARE @SqlMajorVersion TINYINT = CAST(SERVERPROPERTY('ProductMajorVersion') AS TINYINT);
DECLARE @Verbose BIT = 0;
DECLARE @DatabaseName SYSNAME = DB_NAME(DB_ID());
DECLARE @Sql NVARCHAR(MAX);
DECLARE @FailMessage NVARCHAR(MAX) = N'Did not find test sensitivity classifications in output.';
--Don't get this test value as a hit result in the output
DECLARE @Expected VARCHAR(250) = CONCAT('|', ' OutputText | NVARCHAR(MAX) | yes |  |  |  | Label: Highly Confidential <br /> Type: Financial <br /> Rank: CRITICAL <br />  ', '|');

-- Exclude SQL 2017 since sensitivity classification is half-baked in that version
IF EXISTS (SELECT 1 FROM [sys].[system_views] WHERE [name] = 'sensitivity_classifications') AND (@SqlMajorVersion <> 14)
BEGIN
    --Setup
    IF OBJECT_ID('tempdb..#result') IS NOT NULL
    BEGIN
        DROP TABLE #result;
    END
    CREATE TABLE #result ([markdown] VARCHAR(MAX));

    --Get results
    INSERT INTO #result
    EXEC sp_doc @DatabaseName = @DatabaseName, @Verbose = @Verbose;

    --Assert
    IF EXISTS (SELECT 1 FROM #result WHERE [markdown] = @Expected)
        BEGIN
            RETURN;
        END;
    ELSE
        BEGIN
            EXEC [tSQLt].[Fail] @FailMessage;
        END;
END;

END;
GO

/* test sp_doc returns correct table index */
CREATE PROCEDURE [sp_doc].[test sp returns correct table index]
AS
BEGIN
SET NOCOUNT ON;

DECLARE @Verbose BIT = 0;
DECLARE @DatabaseName SYSNAME = DB_NAME(DB_ID());
DECLARE @IndexName SYSNAME = 'idx_IndexTest';
DECLARE @TableName SYSNAME = 'IndexTest';
DECLARE @Sql NVARCHAR(MAX);
DECLARE @FailMessage NVARCHAR(1000) = CONCAT('Did not find table index ', QUOTENAME(@IndexName), ' in markdown output.');
DECLARE @Expected NVARCHAR(250) = CONCAT('| ', 'idx_IndexTest | nonclustered | [id] |  |  |'); --Don't get this test value as a hit result in the output

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



--Assert
IF EXISTS (SELECT 1 FROM #result WHERE [markdown] = @Expected)
    BEGIN
        RETURN;
    END;
ELSE
    EXEC [tSQLt].[Fail] @FailMessage;
END;
GO

/* test sp_doc returns correct view index */
CREATE PROCEDURE [sp_doc].[test sp returns correct view index]
AS
BEGIN
SET NOCOUNT ON;

DECLARE @Verbose BIT = 0;
DECLARE @DatabaseName SYSNAME = DB_NAME(DB_ID());
DECLARE @IndexName SYSNAME = 'idx_IndexTest';
DECLARE @ViewName SYSNAME = 'vw_IndexTest';
DECLARE @TableName SYSNAME = 'IndexTest';
DECLARE @Sql NVARCHAR(MAX);
DECLARE @FailMessage NVARCHAR(1000) = CONCAT('Did not find view index ', QUOTENAME(@IndexName), ' in markdown output.');
DECLARE @Expected NVARCHAR(250) = CONCAT('| ', 'idx_IndexTest | clustered | [id] |  |  |'); --Don't get this test value as a hit result in the output

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

--Assert
IF EXISTS (SELECT 1 FROM #result WHERE [markdown] = @Expected)
    BEGIN
        RETURN;
    END;
ELSE
    EXEC [tSQLt].[Fail] @FailMessage;
END;
GO

/* test sp_doc escapes md right brackets */
CREATE PROCEDURE [sp_doc].[test sp escapes md right brackets]
AS
BEGIN
SET NOCOUNT ON;

DECLARE @Verbose BIT = 0;
DECLARE @DatabaseName SYSNAME = DB_NAME(DB_ID());
DECLARE @TableName SYSNAME = 'TestTable';
DECLARE @Sql NVARCHAR(MAX);
DECLARE @FailMessage NVARCHAR(1000) = N'Did not find  '']'' replaced by ''&#93;'' in markdown output.';
DECLARE @Expected NVARCHAR(250) = N'| Replace | TINYINT | yes |  |  | this is a bracket &#93; %';

--Setup
IF OBJECT_ID('tempdb..#result') IS NOT NULL
BEGIN
    DROP TABLE #result;
END
CREATE TABLE #result ([markdown] VARCHAR(8000));

SET @Sql = N'CREATE TABLE [dbo].' + QUOTENAME(@TableName) + '([Replace] TINYINT);';
EXEC sp_executesql @Sql;

EXEC sp_addextendedproperty
@name = N'Description',
@value = 'this is a bracket ]',
@level0type = N'Schema', @level0name = 'dbo',
@level1type = N'Table',  @level1name = @TableName,
@level2type = N'Column', @level2name = 'Replace';

--Get results
INSERT INTO #result
EXEC sp_doc @DatabaseName = @DatabaseName, @Verbose = @Verbose;

--Assert
IF EXISTS (SELECT 1 FROM #result WHERE [markdown] LIKE @Expected)
    BEGIN
        RETURN;
    END;
ELSE
    EXEC [tSQLt].[Fail] @FailMessage;
END;
GO

/* test sp_doc escapes md pipes */
CREATE PROCEDURE [sp_doc].[test sp escapes md pipes]
AS
BEGIN
SET NOCOUNT ON;

SET NOCOUNT ON;

DECLARE @Verbose BIT = 0;
DECLARE @DatabaseName SYSNAME = DB_NAME(DB_ID());
DECLARE @TableName SYSNAME = 'TestTable';
DECLARE @Sql NVARCHAR(MAX);
DECLARE @FailMessage NVARCHAR(1000) = N'Did not find  ''|'' replaced by ''&#124;'' in markdown output.';
DECLARE @Expected NVARCHAR(250) = N'| Replace | TINYINT | yes |  |  | mario loves &#124;s %';

--Setup
IF OBJECT_ID('tempdb..#result') IS NOT NULL
BEGIN
    DROP TABLE #result;
END
CREATE TABLE #result ([markdown] VARCHAR(8000));

SET @Sql = N'CREATE TABLE [dbo].' + QUOTENAME(@TableName) + '([Replace] TINYINT);';
EXEC sp_executesql @Sql;

EXEC sp_addextendedproperty
@name = N'Description',
@value = 'mario loves |s',
@level0type = N'Schema', @level0name = 'dbo',
@level1type = N'Table',  @level1name = @TableName,
@level2type = N'Column', @level2name = 'Replace';

--Get results
INSERT INTO #result
EXEC sp_doc @DatabaseName = @DatabaseName, @Verbose = @Verbose;

-- Optimization for small azure sql instance
DELETE FROM #result WHERE [markdown] NOT LIKE '| %';

--Assert
IF EXISTS (SELECT 1 FROM #result WHERE [markdown] LIKE @Expected)
    BEGIN
        RETURN;
    END;
ELSE
    EXEC [tSQLt].[Fail] @FailMessage;
END;
GO

/* test sp_doc escapes md ticks */
CREATE PROCEDURE [sp_doc].[test sp escapes md ticks]
AS
BEGIN
SET NOCOUNT ON;

DECLARE @Verbose BIT = 0;
DECLARE @DatabaseName SYSNAME = DB_NAME(DB_ID());
DECLARE @TableName SYSNAME = 'TestTable';
DECLARE @Sql NVARCHAR(MAX);
DECLARE @FailMessage NVARCHAR(1000) = N'Did not find  ''`'' replaced by ''&#96;'' in markdown output.';
DECLARE @Expected NVARCHAR(250) = N'| Replace | TINYINT | yes |  |  | watch out for &#96; season %';

--Setup
IF OBJECT_ID('tempdb..#result') IS NOT NULL
BEGIN
    DROP TABLE #result;
END
CREATE TABLE #result ([markdown] VARCHAR(8000));

SET @Sql = N'CREATE TABLE [dbo].' + QUOTENAME(@TableName) + '([Replace] TINYINT);';
EXEC sp_executesql @Sql;

EXEC sp_addextendedproperty
@name = N'Description',
@value = 'watch out for ` season',
@level0type = N'Schema', @level0name = 'dbo',
@level1type = N'Table',  @level1name = @TableName,
@level2type = N'Column', @level2name = 'Replace';

--Get results
INSERT INTO #result
EXEC sp_doc @DatabaseName = @DatabaseName, @Verbose = @Verbose;

-- Optimization for small azure sql instance
DELETE FROM #result WHERE [markdown] NOT LIKE '| %';

--Assert
IF EXISTS (SELECT 1 FROM #result WHERE [markdown] LIKE @Expected)
    BEGIN
        RETURN;
    END;
ELSE
    EXEC [tSQLt].[Fail] @FailMessage;
END;
GO

/* test sp_doc escapes md line breaks */
CREATE PROCEDURE [sp_doc].[test sp escapes md line breaks]
AS
BEGIN
SET NOCOUNT ON;

DECLARE @Verbose BIT = 0;
DECLARE @DatabaseName SYSNAME = DB_NAME(DB_ID());
DECLARE @TableName SYSNAME = 'TestTable';
DECLARE @Sql NVARCHAR(MAX);
DECLARE @FailMessage NVARCHAR(1000) = N'Did not find line break replaced by ''<br/>'' in markdown output.';
DECLARE @Expected NVARCHAR(250) = N'| Replace | TINYINT | yes |  |  | i want to<br/>break away %';

--Setup
IF OBJECT_ID('tempdb..#result') IS NOT NULL
BEGIN
    DROP TABLE #result;
END
CREATE TABLE #result ([markdown] VARCHAR(8000));

SET @Sql = N'CREATE TABLE [dbo].' + QUOTENAME(@TableName) + '([Replace] TINYINT);';
EXEC sp_executesql @Sql;

EXEC sp_addextendedproperty
@name = N'Description',
@value = 'i want to
break away',
@level0type = N'Schema', @level0name = 'dbo',
@level1type = N'Table',  @level1name = @TableName,
@level2type = N'Column', @level2name = 'Replace';

--Get results
INSERT INTO #result
EXEC sp_doc @DatabaseName = @DatabaseName, @Verbose = @Verbose;

--Assert
IF EXISTS (SELECT 1 FROM #result WHERE [markdown] LIKE @Expected)
    BEGIN
        RETURN;
    END;
ELSE
    EXEC [tSQLt].[Fail] @FailMessage;
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
BEGIN
SET NOCOUNT ON;

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
BEGIN
SET NOCOUNT ON;

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

/************************************
Begin sp_helpme tests
*************************************/

--Clean Class
EXEC tSQLt.DropClass 'sp_helpme';
GO

EXEC tSQLT.NewTestClass 'sp_helpme';
GO

/*
test that sp_sizeoptimiser exists
*/
CREATE PROCEDURE sp_helpme.[test sp succeeds on create]
AS
BEGIN

--Assert
EXEC tSQLt.AssertObjectExists @objectName = 'dbo.sp_helpme', @message = 'Stored procedure sp_helpme does not exist.';

END;
GO

/*
test that sp_helpme errors on non-existant object
*/
CREATE PROCEDURE sp_helpme.[test sp fails for missing object]
AS
BEGIN

--Build
DECLARE @Table SYSNAME = 'dbo.IDontExist';
DECLARE @Database SYSNAME = DB_NAME(DB_ID());
DECLARE @ExpectedMessage NVARCHAR(MAX) = FORMATMESSAGE(N'The object ''%s'' does not exist in database ''%s'' or is invalid for this operation.', @Table, @Database);

--Assert
EXEC [tSQLt].[ExpectException] @ExpectedMessage = @ExpectedMessage, @ExpectedSeverity = 16, @ExpectedState = 1, @ExpectedErrorNumber = 15009
EXEC [sp_helpme] @Table;

END;
GO

/*
test that sp_helpme does not fail for object that exists
*/
CREATE PROCEDURE sp_helpme.[test sp succeeds for object that exists]
AS
BEGIN

--Build
--Assume tSQLt's table tSQLt.CaptureOutputLog always exists
DECLARE @Table SYSNAME = 'tSQLt.CaptureOutputLog';
DECLARE @cmd NVARCHAR(MAX) = N'EXEC [sp_helpme] ''' + @Table + ''';';

--Assert
EXEC tSQLt.ExpectNoException;
EXEC tSQLt.ResultSetFilter 0, @cmd; --Still runs but suppresses undesired output

END;
GO

/*
test first result set of sp_helpme for a table
*/
CREATE PROCEDURE [sp_helpme].[test sp succeeds on a table]
AS
BEGIN

DECLARE @EngineEdition TINYINT = CAST(SERVERPROPERTY('EngineEdition') AS TINYINT);

--Build
--Assume tSQLt's table tSQLt.CaptureOutputLog always exists
DECLARE @Table SYSNAME = 'tSQLt.CaptureOutputLog';
DECLARE @epname SYSNAME = 'Description';
DECLARE @cmd NVARCHAR(MAX) = N'EXEC [sp_helpme] ''' + @Table + ''', ''' + @epname + ''';';

CREATE TABLE #Expected  (
	[name] SYSNAME NOT NULL
	,[owner] NVARCHAR(20) NOT NULL
	,[object_type] NVARCHAR(100) NOT NULL
	,[create_datetime] DATETIME NOT NULL
	,[modify_datetime] DATETIME NOT NULL
	,[ExtendedProperty] SQL_VARIANT NULL
)

IF (@EngineEdition <> 5) --Non-Azure SQL
BEGIN
    INSERT INTO #Expected
    SELECT
	    [Name]					= o.name,
	    [Owner]					= user_name(ObjectProperty(object_id, 'ownerid')),
	    [Type]					= substring(v.name,5,31),
	    [Created_datetime]		= o.create_date,
	    [Modify_datetime]		= o.modify_date,
	    [ExtendedProperty]		= ep.[value]
    FROM sys.all_objects o
	    INNER JOIN master.dbo.spt_values v ON o.type = substring(v.name,1,2) collate DATABASE_DEFAULT
	    LEFT JOIN sys.extended_properties ep ON ep.major_id = o.[object_id]
		    AND ep.[name] = @epname
		    AND ep.minor_id = 0
		    AND ep.class = 1 
    WHERE v.type = 'O9T'
	    AND o.name = 'CaptureOutputLog';
END;
ELSE IF (@EngineEdition = 5) --Azure SQL
BEGIN
    SELECT
			[Name]					= o.name,
			[Owner]					= user_name(ObjectProperty(object_id, ''ownerid'')),
			[Type]					= LOWER(REPLACE(o.type_desc, ''_'', '''')),
			[Created_datetime]		= o.create_date,
			[Modify_datetime]		= o.modify_date,
			[ExtendedProperty]		= ep.[value]
		FROM sys.all_objects o
			LEFT JOIN sys.extended_properties ep ON ep.major_id = o.[object_id]
				AND ep.[name] = @epname
				AND ep.minor_id = 0
				AND ep.class = 1 
		WHERE  o.name = 'CaptureOutputLog';
END;

CREATE TABLE #Actual  (
	[name] SYSNAME NOT NULL
	,[owner] NVARCHAR(20) NOT NULL
	,[object_type] NVARCHAR(100) NOT NULL
	,[create_datetime] DATETIME NOT NULL
	,[modify_datetime] DATETIME NOT NULL
	,[ExtendedProperty] SQL_VARIANT NULL
)
INSERT INTO #Actual
EXEC tSQLt.ResultSetFilter 1, @cmd;

--Assert
EXEC tSQLt.AssertEqualsTable #Expected, #Actual;

END;
GO

/*
test sp_helpme errors on unsupported SQL Server < v12
*/
CREATE PROCEDURE [sp_helpme].[test sp fails on unsupported version]
AS
BEGIN;

DECLARE @version TINYINT = 10;

--Assert
EXEC [tSQLt].[ExpectException] @ExpectedMessage = N'SQL Server versions below 2012 are not supported, sorry!';
EXEC [dbo].[sp_helpme] @SqlMajorVersion = @version;

END;
GO

/*
test sp_helpme works on supported SQL Server >= v12
*/
CREATE PROCEDURE [sp_helpme].[test sp succeeds on supported version]
AS
BEGIN;

DECLARE @version TINYINT = 13;

--Assert
EXEC [tSQLt].[ExpectNoException];
EXEC [dbo].[sp_helpme] @SqlMajorVersion = @version;

END;
GO

/*
test sp_helpme fails for objects in different database
*/
CREATE PROCEDURE [sp_helpme].[test sp fails for obj in different db]
AS
BEGIN;

--Build
DECLARE @Table SYSNAME = 'msdb.dbo.backupset';

--Assert
EXEC [tSQLt].[ExpectException]
    @ExpectedMessage = N'The database name component of the object qualifier must be the name of the current database.',
    @ExpectedSeverity = 16,
    @ExpectedState = 1,
    @ExpectedErrorNumber = 15250;

EXEC [sp_helpme] @Table;

END;
GO



/*
test first result set of sp_helpme for a table
*/
CREATE PROCEDURE [sp_helpme].[test sp succeeds on a table sans identity col]
AS
BEGIN

DECLARE @EngineEdition TINYINT = CAST(SERVERPROPERTY('EngineEdition') AS TINYINT);

--Build
--Assume tSQLt's table tSQLt.Run_LastExecution always exists
DECLARE @Table SYSNAME = 'tSQLt.Run_LastExecution';
DECLARE @epname SYSNAME = 'Description';
DECLARE @cmd NVARCHAR(MAX) = N'EXEC [sp_helpme] ''' + @Table + ''', ''' + @epname + ''';';

CREATE TABLE #Expected  (
	[name] SYSNAME NOT NULL
	,[owner] NVARCHAR(20) NOT NULL
	,[object_type] NVARCHAR(100) NOT NULL
	,[create_datetime] DATETIME NOT NULL
	,[modify_datetime] DATETIME NOT NULL
	,[ExtendedProperty] SQL_VARIANT NULL
)

IF (@EngineEdition <> 5) --Non-Azure SQL
BEGIN
    INSERT INTO #Expected
    SELECT
	    [Name]					= o.name,
	    [Owner]					= user_name(ObjectProperty(object_id, 'ownerid')),
	    [Type]					= substring(v.name,5,31),
	    [Created_datetime]		= o.create_date,
	    [Modify_datetime]		= o.modify_date,
	    [ExtendedProperty]		= ep.[value]
    FROM sys.all_objects o
	    INNER JOIN master.dbo.spt_values v ON o.type = substring(v.name,1,2) collate DATABASE_DEFAULT
	    LEFT JOIN sys.extended_properties ep ON ep.major_id = o.[object_id]
		    AND ep.[name] = @epname
		    AND ep.minor_id = 0
		    AND ep.class = 1 
    WHERE v.type = 'O9T'
	    AND o.name = 'Run_LastExecution';
END;
ELSE IF (@EngineEdition = 5) --Azure SQL
BEGIN
    SELECT
			[Name]					= o.name,
			[Owner]					= user_name(ObjectProperty(object_id, ''ownerid'')),
			[Type]					= LOWER(REPLACE(o.type_desc, ''_'', '''')),
			[Created_datetime]		= o.create_date,
			[Modify_datetime]		= o.modify_date,
			[ExtendedProperty]		= ep.[value]
		FROM sys.all_objects o
			LEFT JOIN sys.extended_properties ep ON ep.major_id = o.[object_id]
				AND ep.[name] = @epname
				AND ep.minor_id = 0
				AND ep.class = 1 
		WHERE  o.name = 'CaptureOutputLog';
END;

CREATE TABLE #Actual  (
	[name] SYSNAME NOT NULL
	,[owner] NVARCHAR(20) NOT NULL
	,[object_type] NVARCHAR(100) NOT NULL
	,[create_datetime] DATETIME NOT NULL
	,[modify_datetime] DATETIME NOT NULL
	,[ExtendedProperty] SQL_VARIANT NULL
)
INSERT INTO #Actual
EXEC tSQLt.ResultSetFilter 1, @cmd;

--Assert
EXEC tSQLt.AssertEqualsTable #Expected, #Actual;

END;
GO

/*
test that sp_helpme succeeds for a stored procedure
*/
CREATE PROCEDURE sp_helpme.[test sp succeeds for a stored procedure]
AS
BEGIN

--Build
--Assume tSQLt's stored procedure tSQLt.ApplyConstraint always exists
DECLARE @StoredProc SYSNAME = 'tSQLt.ApplyConstraint';
DECLARE @cmd NVARCHAR(MAX) = N'EXEC [sp_helpme] ''' + @StoredProc + ''';';

--Assert
EXEC tSQLt.ExpectNoException;
EXEC tSQLt.ResultSetFilter 0, @cmd; --Still runs but suppresses undesired output

END;
GO

/*
test that sp_helpme succeeds for a type
*/
CREATE PROCEDURE sp_helpme.[test sp succeeds for a type]
AS
BEGIN

--Build
DECLARE @Type SYSNAME = 'dbo.SizeOptimiserTableType';
DECLARE @cmd NVARCHAR(MAX) = N'EXEC [sp_helpme] ''' + @Type + ''';';

--Assert
EXEC tSQLt.ExpectNoException;
EXEC tSQLt.ResultSetFilter 0, @cmd; --Still runs but suppresses undesired output

END;
GO

/*
test that sp_helpme succeeds for a type
*/
CREATE PROCEDURE sp_helpme.[test sp succeeds for table with schemabound view]
AS
BEGIN

--Build
DECLARE @Table SYSNAME = 'tSQLt.CaptureOutputLog';
DECLARE @cmd NVARCHAR(MAX) = N'EXEC [sp_helpme] ''' + @Table + ''';';
DECLARE @sql NVARCHAR(MAX) = N'
CREATE VIEW dbo.SchemaBoundView
WITH SCHEMABINDING
AS
SELECT [id] FROM tSQLt.CaptureOutputLog;';

IF EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'dbo.SchemaBoundView'))
    DROP VIEW dbo.SchemaBoundView;

EXEC sp_executesql @sql;

--Assert
EXEC tSQLt.ExpectNoException;
EXEC tSQLt.ResultSetFilter 0, @cmd; --Still runs but suppresses undesired output

END;
GO

/************************************
End sp_helpme tests
*************************************/
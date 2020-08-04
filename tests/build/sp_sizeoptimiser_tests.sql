/************************************
Begin sp_sizeoptimiser tests
*************************************/

--Clean Class
EXEC tSQLt.DropClass 'sp_sizeoptimiser';
GO

EXEC tSQLT.NewTestClass 'sp_sizeoptimiser';
GO

/*
test that sp_sizeoptimiser exists
*/
CREATE PROCEDURE [sp_sizeoptimiser].[test sp succeeds on create]
AS
BEGIN

--Assert
EXEC tSQLt.AssertObjectExists @objectName = 'dbo.sp_sizeoptimiser', @message = 'Stored procedure sp_sizeoptimiser does not exist.';

END;
GO

/*
test that SizeOptimiserTableType exists
*/
CREATE PROCEDURE [sp_sizeoptimiser].[test sp succeeds on dependent table type create]
AS
BEGIN

DECLARE @actual BIT = 0;
DECLARE @expected BIT = 1;

--Check for table type 
SELECT @actual = 1
FROM sys.table_types
WHERE [name] = 'SizeOptimiserTableType'

--Assert
EXEC tSQLt.AssertEquals @expected, @actual, @message = 'User defined table type SizeOptimiserTableType does not exist';

END;
GO

/*
test that incorrect @IndexNumThreshold throws error 
*/
CREATE PROCEDURE [sp_sizeoptimiser].[test sp fails on incorrect @IndexNumThreshold]
AS
BEGIN

--Assert
EXEC tSQLt.ExpectException @ExpectedMessage = N'@IndexNumThreshold must be between 1 and 999.', @ExpectedSeverity = 16, @ExpectedState = 1, @ExpectedErrorNumber = 50000
EXEC dbo.sp_sizeoptimiser @IndexNumThreshold = 0, @Verbose = 0;

END;
GO

/* test result set has correct table schema*/
CREATE PROCEDURE [sp_sizeoptimiser].[test sp succeeds with result set metadata]
AS
BEGIN

DECLARE @version NVARCHAR(MAX) = @@VERSION;

EXEC tSQLt.AssertResultSetsHaveSameMetaData 
	@expectedCommand = N'CREATE TABLE #results
						([check_num]	INT NOT NULL,
						[check_type]	NVARCHAR(50) NOT NULL,
						[db_name]		SYSNAME NOT NULL,
						[obj_type]		SYSNAME NOT NULL,
						[obj_name]		NVARCHAR(400) NOT NULL,
						[col_name]		SYSNAME NULL,
						[message]		NVARCHAR(500) NULL,
						[ref_link]		NVARCHAR(500) NULL);  
						SELECT * FROM #results;',
	@actualCommand = N'EXEC dbo.sp_sizeoptimiser @Verbose = 0;';

END;
GO

/*
test that passing @IncludeDatabases 
and @ExcludeDatabases fails
*/
CREATE PROCEDURE [sp_sizeoptimiser].[test sp fails using include and exclude params]
AS
BEGIN

--Build
DECLARE @IncludeDatabases [dbo].[SizeOptimiserTableType]; 
DECLARE @ExcludeDatabases [dbo].[SizeOptimiserTableType]; 

INSERT INTO @IncludeDatabases
VALUES ('master');

INSERT INTO @ExcludeDatabases
VALUES ('model');

--Assert
EXEC [tSQLt].[ExpectException] @ExpectedMessage = N'Both @IncludeDatabases and @ExcludeDatabases cannot be specified.', @ExpectedSeverity = 16, @ExpectedState = 1, @ExpectedErrorNumber = 50000
EXEC [dbo].[sp_sizeoptimiser] NULL, @IncludeDatabases = @IncludeDatabases, @ExcludeDatabases = @ExcludeDatabases, @Verbose = 0;

END;
GO


/*
test failure on unsupported SQL Server < v12
*/
CREATE PROCEDURE [sp_sizeoptimiser].[test sp fails on unsupported version]
AS
BEGIN;

--Build
DECLARE @version TINYINT = 10;

--Assert
EXEC [tSQLt].[ExpectException] @ExpectedMessage = N'SQL Server versions below 2012 are not supported, sorry!', @ExpectedSeverity = 16, @ExpectedState = 1, @ExpectedErrorNumber = 50000
EXEC [dbo].[sp_sizeoptimiser] @SqlMajorVersion = @version, @Verbose = 0;

END;
GO

/*
test success on supported SQL Server >= v12
*/
CREATE PROCEDURE [sp_sizeoptimiser].[test sp succeeds on supported version]
AS
BEGIN;

--Build
DECLARE @version TINYINT = 13;
DECLARE @IncludeDatabases [dbo].[SizeOptimiserTableType];
DECLARE @command NVARCHAR(MAX) = N'EXEC [dbo].[sp_sizeoptimiser] @SqlMajorVersion = ' + CAST(@version AS NVARCHAR(2)) + ', @Verbose = 0;'

--Assert
EXEC [tSQLt].[ExpectNoException]
EXEC [tSQLt].[SuppressOutput] @command = @command;

END;
GO


/*
test success on supported SQL Server >= v12
*/
CREATE PROCEDURE [sp_sizeoptimiser].[test sp succeeds with verbose mode]
AS
BEGIN;

--Build
DECLARE @version TINYINT = 13;
DECLARE @IncludeDatabases [dbo].[SizeOptimiserTableType]; 
DECLARE @DbName SYSNAME = DB_NAME(DB_ID());

INSERT INTO @IncludeDatabases
VALUES (@DbName);

--Assert
EXEC [tSQLt].[ExpectNoException]
DECLARE @command NVARCHAR(MAX) = 'EXEC [dbo].[sp_sizeoptimiser] @Verbose = 1;';
EXEC [tSQLt].[SuppressOutput] @command = @command;

END;
GO

/*
test success on @ExcludeDatabases
*/
CREATE PROCEDURE [sp_sizeoptimiser].[test sp succeeds with @ExcludeDatabases]
AS
BEGIN;

--Build
DECLARE @version TINYINT = 13;
DECLARE @ExcludeDatabases [dbo].[SizeOptimiserTableType]; 

INSERT INTO @ExcludeDatabases
VALUES ('master');

--Assert
EXEC [tSQLt].[ExpectNoException]
EXEC [dbo].[sp_sizeoptimiser] @ExcludeDatabases = @ExcludeDatabases, @Verbose = 0;

END;
GO

/*
test fail on non-existant databases
*/
CREATE PROCEDURE [sp_sizeoptimiser].[test sp fails with imaginary database]
AS
BEGIN;

--Build
DECLARE @IncludeDatabases [dbo].[SizeOptimiserTableType]; 
DECLARE @DbName SYSNAME = 'BlackLivesMatter';
DECLARE @ExpectedMessage NVARCHAR(MAX) = FORMATMESSAGE('Supplied databases do not exist or are not accessible: %s.', @DbName);

INSERT INTO @IncludeDatabases
VALUES (@DbName);

--Assert
EXEC [tSQLt].[ExpectException] @ExpectedMessage = @ExpectedMessage, @ExpectedSeverity = 16, @ExpectedState = 1, @ExpectedErrorNumber = 50000
EXEC [dbo].[sp_sizeoptimiser] @IncludeDatabases = @IncludeDatabases;

END;
GO

/*
test success on SQLExpress
*/
CREATE PROCEDURE [sp_sizeoptimiser].[test sp succeeds in Express Mode]
AS
BEGIN;

--Check if testing on Azure SQL
DECLARE @EngineEdition TINYINT = CAST(ServerProperty('EngineEdition') AS TINYINT);

IF (@EngineEdition <> 5) -- Not Azure SQL
    BEGIN
        --Build
        DECLARE @IsExpress BIT = 1;

        --Assert
        EXEC [tSQLt].[ExpectNoException]
        EXEC [dbo].[sp_sizeoptimiser] @IsExpress = @IsExpress, @Verbose = 0;
    END;
END;
GO

/************************************
End sp_sizeoptimiser tests
*************************************/

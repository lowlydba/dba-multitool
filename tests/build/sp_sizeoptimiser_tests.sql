SET NOCOUNT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;

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

DECLARE @ObjectName NVARCHAR(1000) = N'dbo.sp_sizeoptimiser';
DECLARE @ErrorMessage NVARCHAR(MAX) = N'Stored procedure sp_sizeoptimiser does not exist.';

--Assert
EXEC tSQLt.AssertObjectExists 
	@objectName = @objectName
	,@message = @ErrorMessage;

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
DECLARE @ErrorMessage NVARCHAR(MAX) = N'User defined table type SizeOptimiserTableType does not exist';
DECLARE @ObjectName SYSNAME = N'SizeOptimiserTableType';

--Check for table type 
SELECT @actual = 1
FROM [sys].[table_types]
WHERE [name] = @ObjectName;

--Assert
EXEC tSQLt.AssertEquals @expected
	,@actual
	,@message = @ErrorMessage;

END;
GO

/*
test that incorrect @IndexNumThreshold throws error 
*/
CREATE PROCEDURE [sp_sizeoptimiser].[test sp fails on incorrect @IndexNumThreshold]
AS
BEGIN

DECLARE @ExpectedMessage NVARCHAR(MAX) = N'@IndexNumThreshold must be between 1 and 999.';
DECLARE @ExpectedSeverity TINYINT = 16;
DECLARE @ExpectedState TINYINT = 1;
DECLARE @ExpectedErrorNumber INT = 50000;
DECLARE @IndexNumThreshold TINYINT = 0;
DECLARE @Verbose BIT = 0;

--Assert
EXEC tSQLt.ExpectException 
	@ExpectedMessage = @ExpectedMessage
	,@ExpectedSeverity = @ExpectedSeverity
	,@ExpectedState = @ExpectedState
	,@ExpectedErrorNumber = @ExpectedErrorNumber;
EXEC dbo.sp_sizeoptimiser 
	@IndexNumThreshold = @IndexNumThreshold
	,@Verbose = @Verbose;

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
DECLARE @ExpectedMessage NVARCHAR(MAX) = 'Both @IncludeDatabases and @ExcludeDatabases cannot be specified.';
DECLARE @ExpectedSeverity TINYINT = 16;
DECLARE @ExpectedState TINYINT = 1;
DECLARE @ExpectedErrorNumber INT = 50000;
DECLARE @Verbose BIT = 0;

INSERT INTO @IncludeDatabases
VALUES ('master');

INSERT INTO @ExcludeDatabases
VALUES ('model');

--Assert
EXEC [tSQLt].[ExpectException] @ExpectedMessage = @ExpectedMessage
	,@ExpectedSeverity = @ExpectedSeverity
	,@ExpectedState = @ExpectedState
	,@ExpectedErrorNumber = @ExpectedErrorNumber;
EXEC [dbo].[sp_sizeoptimiser] 
	NULL
	,@IncludeDatabases = @IncludeDatabases
	,@ExcludeDatabases = @ExcludeDatabases
	,@Verbose = @Verbose;

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
DECLARE @Verbose BIT = 0;
DECLARE @ExpectedMessage NVARCHAR(MAX) = 'SQL Server versions below 2012 are not supported, sorry!';
DECLARE @ExpectedSeverity TINYINT = 16;
DECLARE @ExpectedState TINYINT = 1;
DECLARE @ExpectedErrorNumber INT = 50000;

--Assert
EXEC [tSQLt].[ExpectException] @ExpectedMessage = @ExpectedMessage
	,@ExpectedSeverity = @ExpectedSeverity
	,@ExpectedState = @ExpectedState
	,@ExpectedErrorNumber = @ExpectedErrorNumber;
EXEC [dbo].[sp_sizeoptimiser] 
	@SqlMajorVersion = @version
	,@Verbose = @Verbose;

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
DECLARE @Verbose BIT = 0;
DECLARE @command NVARCHAR(MAX) = CONCAT(N'EXEC [dbo].[sp_sizeoptimiser] @SqlMajorVersion = ',@version, ', @Verbose =', @Verbose, ';');

--Assert
EXEC [tSQLt].[ExpectNoException];
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
DECLARE @Verbose BIT = 1;
DECLARE @command NVARCHAR(MAX) = CONCAT('EXEC [dbo].[sp_sizeoptimiser] @Verbose =', @Verbose, ';');

INSERT INTO @IncludeDatabases
VALUES (@DbName);

--Assert
EXEC [tSQLt].[ExpectNoException];
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
DECLARE @Verbose BIT = 0;

INSERT INTO @ExcludeDatabases
VALUES ('master');

--Assert
EXEC [tSQLt].[ExpectNoException];
EXEC [dbo].[sp_sizeoptimiser] 
	@ExcludeDatabases = @ExcludeDatabases
	,@Verbose = @Verbose;

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
DECLARE @ExpectedSeverity TINYINT = 16;
DECLARE @ExpectedState TINYINT = 1;
DECLARE @ExpectedErrorNumber INT = 50000;

INSERT INTO @IncludeDatabases
VALUES (@DbName);

--Assert
EXEC [tSQLt].[ExpectException] @ExpectedMessage = @ExpectedMessage
	,@ExpectedSeverity = @ExpectedSeverity
	,@ExpectedState = @ExpectedState
	,@ExpectedErrorNumber = @ExpectedErrorNumber;
EXEC [dbo].[sp_sizeoptimiser] @IncludeDatabases = @IncludeDatabases;

END;
GO

/*
test success in Express Mode
*/
CREATE PROCEDURE [sp_sizeoptimiser].[test sp succeeds in Express Mode]
AS
BEGIN;

--Check if testing on Azure SQL
DECLARE @EngineEdition TINYINT = CAST(ServerProperty('EngineEdition') AS TINYINT);
DECLARE @Verbose BIT = 0;
DECLARE @AzureSQLEngine TINYINT = 5;

IF (@EngineEdition <> @AzureSQLEngine) -- Not Azure SQL
    BEGIN
        --Build
        DECLARE @IsExpress BIT = 1;

        --Assert
        EXEC [tSQLt].[ExpectNoException];
        EXEC [dbo].[sp_sizeoptimiser] 
			@IsExpress = @IsExpress
			,@Verbose = @Verbose;
    END;

ELSE
	BEGIN;
		EXEC [tSQLt].[ExpectNoException];
        EXEC [dbo].[sp_sizeoptimiser]
			@Verbose = @Verbose;
	END;
END;
GO

/************************************
End sp_sizeoptimiser tests
*************************************/

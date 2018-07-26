USE [tSQLt]
GO

EXEC tSQLT.NewTestClass 'testSizeOptimiser';
GO

/* test that sp_sizeoptimiser exists*/
CREATE PROCEDURE testSizeOptimiser.[test that sp_sizeoptimiser exists]
AS
BEGIN

--Assert
EXEC tSQLt.AssertObjectExists @objectName = 'master.dbo.sp_sizeoptimiser', @message = 'Stored procedure sp_sizeoptimiser does not exist.';

END;
GO

/* test that SizeOptimiserTableType exists */
CREATE PROCEDURE testSizeOptimiser.[test that SizeOptimiserTableType exists]
AS
BEGIN

DECLARE @actual BIT = 0;
DECLARE @expected BIT = 1;

--Check for table type 
SELECT @actual = 1
FROM master.sys.table_types
WHERE [name] = 'SizeOptimiserTableType'

--Assert
EXEC tSQLt.AssertEquals @expected, @actual, @message = 'User defined table type SizeOptimiserTableType does not exist';

END;
GO

/* test that incorrect @IndexNumThreshold throws error */
CREATE PROCEDURE testSizeOptimiser.[test that incorrect @IndexNumThreshold throws error]
AS
BEGIN

--Assert
EXEC tSQLt.ExpectException @ExpectedMessage = N'@IndexNumThreshold must be between 1 and 999.', @ExpectedSeverity = 16, @ExpectedState = 1, @ExpectedErrorNumber = 50000
EXEC master.dbo.sp_sizeoptimiser @IndexNumThreshold = 0

END;
GO


/* test that incorrect @IndexNumThreshold throws error */
CREATE PROCEDURE testSizeOptimiser.[test result set metadata is correct]
AS
BEGIN

--Build test result table
CREATE TABLE #results
				([check_num]	INT NOT NULL,
				[check_type]	NVARCHAR(50) NOT NULL,
				[db_name]		SYSNAME NOT NULL,
				[obj_type]		SYSNAME NOT NULL,
				[obj_name]		SYSNAME NOT NULL,
				[col_name]		SYSNAME NULL,
				[message]		NVARCHAR(500) NULL,
				[ref_link]		NVARCHAR(500) NULL);

EXEC tSQLt.AssertResultSetsHaveSameMetaData 
    'CREATE TABLE #results
				([check_num]	INT NOT NULL,
				[check_type]	NVARCHAR(50) NOT NULL,
				[db_name]		SYSNAME NOT NULL,
				[obj_type]		SYSNAME NOT NULL,
				[obj_name]		SYSNAME NOT NULL,
				[col_name]		SYSNAME NULL,
				[message]		NVARCHAR(500) NULL,
				[ref_link]		NVARCHAR(500) NULL);        
    SELECT * FROM #results',
    'EXEC master.dbo.sp_sizeoptimiser;'

END;
GO


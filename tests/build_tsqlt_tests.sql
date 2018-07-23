USE [tSQLt]
GO

EXEC tSQLT.NewTestClass 'testSizeOptimiser';
GO

CREATE PROCEDURE testSizeOptimiser.[test that sp_sizeoptimiser exists]
AS
BEGIN

--Assert
EXEC tSQLt.AssertObjectExists @objectName = 'master.dbo.sp_sizeoptimiser', @message = 'Stored procedure sp_sizeoptimiser does not exist.';

END;
GO

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

CREATE PROCEDURE testSizeOptimiser.[test that incorrect @IndexNumThreshold throws error]
AS
BEGIN

--Assert
EXEC tSQLt.ExpectException @ExpectedMessage = N'@IndexNumThreshold must be between 1 and 999.', @ExpectedSeverity = 16, @ExpectedState = 1, @ExpectedErrorNumber = 50000
EXEC master.dbo.sp_sizeoptimiser @IndexNumThreshold = 0

END;
GO

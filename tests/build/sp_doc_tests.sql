SET NOCOUNT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;

/************************************
Begin sp_doc tests
*************************************/

--Clean Class
EXEC tSQLt.DropClass 'sp_doc';
GO

EXEC tSQLT.NewTestClass 'sp_doc';
GO

/*
test that sp_doc exists
*/
CREATE PROCEDURE [sp_doc].[test sp succeeds on create]
AS
BEGIN;

DECLARE @ObjectName NVARCHAR(1000) = N'dbo.sp_doc';
DECLARE @ErrorMessage NVARCHAR(MAX) = N'Stored procedure sp_doc does not exist.';

--Assert
EXEC tSQLt.AssertObjectExists @objectName = @objectName, @message = @ErrorMessage;

END;
GO

/*
test sp_doc doesn't error
*/
CREATE PROCEDURE [sp_doc].[test sp succeeds on valid db]
AS
BEGIN;

DECLARE @db SYSNAME = DB_NAME(DB_ID());
DECLARE @command NVARCHAR(MAX) = '[dbo].[sp_doc] @DatabaseName = ' + @db + ';';

--Assert
EXEC [tSQLt].[ExpectNoException];
EXEC [tSQLt].[SuppressOutput] @command = @command;

END;
GO

/*
test sp_doc emoji mode doesn't error
*/
CREATE PROCEDURE [sp_doc].[test sp succeeds in emoji mode]
AS
BEGIN;

DECLARE @db SYSNAME = DB_NAME(DB_ID());
DECLARE @command NVARCHAR(MAX) = '[dbo].[sp_doc] @DatabaseName = ' + @db + ', @Emojis = 1;';

--Assert
EXEC [tSQLt].[ExpectNoException];
EXEC [tSQLt].[SuppressOutput] @command = @command;

END;
GO

/*
test sp_doc unlimited stored proc length doesn't error
*/
CREATE PROCEDURE [sp_doc].[test sp succeeds with unlimited sp output]
AS
BEGIN;

DECLARE @db SYSNAME = DB_NAME(DB_ID());
DECLARE @command NVARCHAR(MAX) = '[dbo].[sp_doc] @DatabaseName = ' + @db + ', @LimitStoredProcLength = 1;';

--Assert
EXEC [tSQLt].[ExpectNoException];
EXEC [tSQLt].[SuppressOutput] @command = @command;

END;
GO

/*
test sp_doc errors on invalid db
*/
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

/*
test sp_doc succeeds on assume current db if none given
*/
CREATE PROCEDURE [sp_doc].[test sp succeeds on current db if none given]
AS
BEGIN;

DECLARE @Verbose BIT = 0;
DECLARE @command NVARCHAR(MAX) = CONCAT('[dbo].[sp_doc] @Verbose = ', @Verbose, ';');

--Assert
EXEC [tSQLt].[ExpectNoException];
EXEC [tSQLt].[SuppressOutput] @command = @command;

END;
GO

/*
test sp_doc fails on unsupported SQL Server < v12
*/
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

/*
test sp_doc succeeds on supported SQL Server >= v12
*/
CREATE PROCEDURE [sp_doc].[test sp succeeds on supported version]
AS
BEGIN;

DECLARE @version TINYINT = 13;
DECLARE @Verbose BIT = 0;
DECLARE @command NVARCHAR(MAX) = CONCAT('[dbo].[sp_doc] @SqlMajorVersion = ', @version, ', @Verbose = ', @Verbose, ';');

--Assert
EXEC [tSQLt].[ExpectNoException];
EXEC [tSQLt].[SuppressOutput] @command = @command;

END;
GO

/*
test sp_doc returns correct metadata
*/
CREATE PROCEDURE [sp_doc].[test sp succeeds on returning desired metadata]
AS
BEGIN;

EXEC tSQLt.AssertResultSetsHaveSameMetaData
    'SELECT CAST(''test'' AS NVARCHAR(MAX)) as [value]',
    'EXEC [dbo].[sp_doc] @Verbose = 0';

END;
GO

/*
test sp_doc returns correct minimum rows
*/
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
        EXEC tSQLt.Fail @FailMessage, @ReturnedRows;
    END;

END;
GO

/************************************
End sp_doc tests
*************************************/
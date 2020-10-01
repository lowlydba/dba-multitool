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

--Assert
EXEC tSQLt.AssertObjectExists @objectName = 'dbo.sp_doc', @message = 'Stored procedure sp_doc does not exist.';

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

DECLARE @db SYSNAME = 'StarshipVoyager';

--Assert
EXEC [tSQLt].[ExpectException] @ExpectedMessage = N'Database not available.';
EXEC [dbo].[sp_doc] @DatabaseName = @db;

END;
GO

/*
test sp_doc can assume current db if none given
*/
CREATE PROCEDURE [sp_doc].[test sp succeeds on current db if none given]
AS
BEGIN;

DECLARE @command NVARCHAR(MAX) = '[dbo].[sp_doc];';

--Assert
EXEC [tSQLt].[ExpectNoException];
EXEC [tSQLt].[SuppressOutput] @command = @command;

END;
GO

/*
test sp_doc errors on unsupported SQL Server < v12
*/
CREATE PROCEDURE [sp_doc].[test sp fails on unsupported version]
AS
BEGIN;

DECLARE @version TINYINT = 10;

--Assert
EXEC [tSQLt].[ExpectException] @ExpectedMessage = N'SQL Server versions below 2012 are not supported, sorry!';
EXEC [dbo].[sp_doc] @SqlMajorVersion = @version;

END;
GO

/*
test sp_doc works on supported SQL Server >= v12
*/
CREATE PROCEDURE [sp_doc].[test sp succeeds on supported version]
AS
BEGIN;

DECLARE @version TINYINT = 13;
DECLARE @command NVARCHAR(MAX) = '[dbo].[sp_doc] @SqlMajorVersion = ' + CAST(@version AS NVARCHAR(4)) + ';';

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
    'EXEC sp_doc';

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

EXEC sp_doc;
SET @ReturnedRows = @@ROWCOUNT;

IF (@TargetRows > @ReturnedRows)
    BEGIN;
        EXEC tSQLt.Fail 'Minimum number of rows were not returned.', @ReturnedRows;
    END;

END;
GO


/************************************
End sp_doc tests
*************************************/
/************************************
Begin sp_doc tests
*************************************/

--Clean Class
EXEC tSQLt.DropClass 'testspdoc';
GO

EXEC tSQLT.NewTestClass 'testspdoc';
GO

/*
test that sp_doc exists
*/
CREATE PROCEDURE testspdoc.[test sp_doc exists]
AS
BEGIN;

--Assert
EXEC tSQLt.AssertObjectExists @objectName = 'dbo.sp_doc', @message = 'Stored procedure sp_doc does not exist.';

END;
GO

/*
test sp_doc doesn't error
*/
CREATE PROCEDURE testspdoc.[test sp_doc does not error on valid db]
AS
BEGIN;

DECLARE @db SYSNAME = 'tSQLt';

--Assert
EXEC [tSQLt].[ExpectNoException];
EXEC [dbo].[sp_doc] @DatabaseName = @db;

END;
GO


/************************************
End sp_doc tests
*************************************/
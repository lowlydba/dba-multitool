/************************************
Begin sp_estindex tests
*************************************/

--Clean Class
EXEC tSQLt.DropClass 'sp_estindex';
GO

EXEC tSQLT.NewTestClass 'sp_estindex';
GO

/*
test that sp_estindex exists
*/
CREATE PROCEDURE [sp_estindex].[test sp succeeds on create]
AS
BEGIN

--Assert
EXEC tSQLt.AssertObjectExists @objectName = 'dbo.sp_estindex', @message = 'Stored procedure sp_estindex does not exist.';

END;
GO

/************************************
End sp_estindex tests
*************************************/

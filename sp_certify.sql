SET NOCOUNT OFF;
SET ANSI_NULLS ON;
GO

/***************************/
/* Create stored procedure */
/***************************/
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_certify]') AND [type] IN (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[sp_certify] AS';
END
GO

ALTER PROCEDURE [dbo].[sp_certify]
    @SchemaName SYSNAME = 'dbo'
    ,@StoredProcName SYSNAME
	,@DatabaseName SYSNAME = NULL
    ,@Permission VARCHAR(MAX)
	/* Parameters defined here for testing only */
	,@SqlMajorVersion TINYINT = 0
	,@SqlMinorVersion SMALLINT = 0
WITH RECOMPILE
AS

/*
sp_certify - Certificate sign stored procedures with elevated permissions.

Based on Erland Sommarskog's "Packaging Permissions in Stored Procedures" (https://sommarskog.se/grantperm.html)
For signing that requires server level permissions, see https://sommarskog.se/grantperm/GrantPermsToSP_server_2008.sql.txt

Part of the DBA MultiTool https://dba-multitool.org

Version: 20221111

=========

MIT License

Copyright (c) 2022 John McCall

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
documentation files (the "Software"), to deal in the Software without restriction, including without limitation
the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software,
and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial
portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED
TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.

=========

Example:

    -- Sign a stored procedure that will make an update to dbo.MyTable in the same database
	EXEC dbo.sp_certify @SchemaName = 'dbo', @StoredProcName = 'MyStoredProc', @Permission = 'UPDATE ON dbo.MyTable';

    -- Sign a stored procedure that will make an update to OtherDatabase.dbo.MyTable;
    EXEC dbo.sp_certify @SchemaName = 'dbo', @StoredProcName = 'MyStoredProc', @Permission = 'UPDATE ON dbo.MyTable', @DatabaseName = 'OtherDatabase';

*/

BEGIN
	SET NOCOUNT ON;

    DECLARE @Rando CHAR(36) = CONVERT(CHAR(36), NEWID())
        ,@CertName SYSNAME = CONCAT('SIGN ', @StoredProcName)
        ,@SQL NVARCHAR(MAX);

    -- Check for existing cert/signature
    IF EXISTS (SELECT 1 FROM sys.certificates c WHERE c.name = @CertName)
    BEGIN
        -- Drop existing signature
        IF EXISTS (SELECT 1 FROM sys.certificates c INNER JOIN sys.crypt_properties cp ON c.thumbprint = cp.thumbprint
                    WHERE c.name = @CertName AND cp.major_id = OBJECT_ID(@QStoredProcName))
        BEGIN
            SELECT @SQL = CONCAT('DROP SIGNATURE FROM ', QUOTENAME(@SchemaName), '.', QUOTENAME(@StoredProcName), ' BY CERTIFICATE ', QUOTENAME(@CertName), ';');
            EXEC sp_executesql @SQL;
        END;

        -- Drop existing cert
        SELECT @SQL = CONCAT('DROP CERTIFICATE ', QUOTENAME(@CertName), ';');
        EXEC sp_executesql @SQL;
    END;

    -- Create new cert
    SELECT @SQL = CONCAT('CREATE CERTIFICATE ', QUOTENAME(@CertName), ' ENCRYPTION BY PASSWORD ''', @Rando, ''' WITH SUBJECT = ', @StoredProcName, ';');
    EXEC sp_executesql @SQL;

    -- Sign stored proc with cert
    SELECT @SQL = CONCAT('ADD SIGNATURE TO ', QUOTENAME(@SchemaName), '.', QUOTENAME(@StoredProcName), ' BY CERTIFICATE ', QUOTENAME(@CertName), ' WITH PASSWORD ''', @Rando, ''';');
    EXEC sp_executesql @SQL;

    -- Private key not needed, cover our tracks
    SELECT @SQL = CONCAT('ALTER CERTIFICATE ', QUOTENAME(@CertName), ' REMOVE PRIVATE KEY;');
    EXEC sp_executesql @SQL;

    IF (@DatabaseName IS NOT NULL)
    BEGIN
        -- Import cert and create user in another database
        DECLARE @CertID INT = CERT_ID(QUOTENAME(@CertName));
        DECLARE @PublicKey VARBINARY(MAX) = CERTENCODED(@CertID);
        DECLARE @TargetDatabaseCertName SYSNAME = CONCAT('SIGN ', DB_NAME(), '.', @SchemaName, '.', @StoredProcName);

        -- Create cert
        SELECT @SQL = CONCAT('USE ', QUOTENAME(@DatabaseName), ' ;',
        'IF EXISTS (SELECT 1 FROM sys.certificates c WHERE QUOTENAME(c.name) = ''', @TargetDatabaseCertName, '''
        BEGIN
            DROP USER IF EXISTS ', QUOTENAME(@TargetDatabaseCertName), ';
            DROP CERTIFICATE ', QUOTENAME(@TargetDatabaseCertName), ';
        END');
        EXEC sp_executesql @SQL;

        SELECT @SQL = CONCAT('USE ', QUOTENAME(@DatabaseName), ';',
        'CREATE CERTIFICATE ', QUOTENAME(@TargetDatabaseCertName), ' FROM BINARY = ', CONVERT(VARCHAR(MAX), @PublicKey, 1), ';');
        EXEC sp_executesql @SQL;

        -- Create cert based user
        SELECT @SQL = CONCAT('USE ', QUOTENAME(@DatabaseName), ';',
        'CREATE USER ', QUOTENAME(@TargetDatabaseCertName), ' FROM CERTIFICATE ', QUOTENAME(@TargetDatabaseCertName), ';');
        EXEC sp_executesql @SQL;

        -- Grant permission to cert
        SELECT @SQL = CONCAT('USE ', QUOTENAME(@DatabaseName), ';',
        'GRANT ', @Permission, ' TO ', QUOTENAME(@TargetDatabaseCertName), ';');
        EXEC sp_executesql @SQL;
    END;
    ELSE
    BEGIN
        -- Grant permissions to cert in same database
        SELECT @SQL = CONCAT('GRANT ', @Permission, ' TO ', QUOTENAME(@CertName), ';');
        EXEC sp_executesql @SQL;
    END

END;

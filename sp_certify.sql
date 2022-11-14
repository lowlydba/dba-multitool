SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
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
	,@TargetDatabaseName SYSNAME = NULL
    ,@Permission VARCHAR(MAX)
    ,@Verbose BIT = 0
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

Note: sp_certify must be in the same database as the stored procedure to be signed.

Example:

    -- Sign a stored procedure that will make an update to dbo.MyTable in the same database
	EXEC dbo.sp_certify @SchemaName = 'dbo', @StoredProcName = 'MyStoredProc', @Permission = 'UPDATE ON dbo.MyTable';

    -- Sign a stored procedure that will make an update to OtherDatabase.dbo.MyTable;
    EXEC dbo.sp_certify @SchemaName = 'dbo', @StoredProcName = 'MyStoredProc', @Permission = 'UPDATE ON schema::dbo', @TargetDatabaseName = 'OtherDatabase';

*/

BEGIN
	SET NOCOUNT ON;

    DECLARE @Rando CHAR(36) = CONVERT(CHAR(36), NEWID())
        ,@CertName SYSNAME = CONCAT('SIGN ', @StoredProcName)
        ,@SQL NVARCHAR(MAX)
        ,@Msg NVARCHAR(MAX);

    DECLARE @CertUser SYSNAME = CONCAT(@CertName, '$CertUser');

    -- Command templates
    DECLARE @DropCert NVARCHAR(1000) = 'DROP CERTIFICATE %s;',
        @AlterCert NVARCHAR(1000) = 'ALTER CERTIFICATE %s REMOVE PRIVATE KEY;',
        @CreateCert NVARCHAR(1000) = 'CREATE CERTIFICATE %s ENCRYPTION BY PASSWORD = ''%s'' WITH SUBJECT = ''%s'';',
        @CreateCertBin NVARCHAR(1000) = 'CREATE CERTIFICATE %s FROM BINARY = %s;',
        @DropUser NVARCHAR(1000) = 'DROP USER IF EXISTS %s;',
        @CreateUser NVARCHAR(1000) = 'CREATE USER %s FROM CERTIFICATE %s;',
        @DropSig NVARCHAR(1000) = 'DROP SIGNATURE FROM %s.%s BY CERTIFICATE %s;',
        @AddSig NVARCHAR(1000) = 'ADD SIGNATURE TO %s.%s BY CERTIFICATE %s WITH PASSWORD = ''%s'';'
        ;

    BEGIN TRY
        -- Validate params
        IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE [name] = @SchemaName)
        BEGIN
            SELECT @Msg = CONCAT('Schema ', QUOTENAME(@SchemaName), ' does not exist in ''', DB_NAME(), '''.');
            RAISERROR(@Msg, 16, 1);
        END;

        IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE [type_desc] = 'SQL_STORED_PROCEDURE' AND [name] = @StoredProcName)
        BEGIN
            SELECT @Msg = CONCAT('Stored procedure ', QUOTENAME(@StoredProcName), ' does not exist in ''', DB_NAME(), '''.');
            RAISERROR(@Msg, 16, 1);
        END;

        IF (@TargetDatabaseName IS NOT NULL)
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM sys.sysdatabases WHERE [name] = @TargetDatabaseName)
            BEGIN
                SELECT @Msg = CONCAT('Database ', QUOTENAME(@TargetDatabaseName), ' does not exist.');
                RAISERROR(@Msg, 16, 1);
            END;
            IF (@TargetDatabaseName = DB_NAME())
            BEGIN
                SELECT @TargetDatabaseName = NULL;
            END;
        END;

        -- Check for existing cert/signature
        IF EXISTS (SELECT 1 FROM sys.certificates c WHERE c.name = @CertName)
        BEGIN
            -- Drop existing signature
            IF EXISTS (SELECT 1 FROM sys.certificates c INNER JOIN sys.crypt_properties cp ON c.thumbprint = cp.thumbprint
                        WHERE c.name = @CertName AND OBJECT_NAME(cp.major_id) = @StoredProcName)
            BEGIN
                SELECT @SQL = FORMATMESSAGE(@DropSig, QUOTENAME(@SchemaName), QUOTENAME(@StoredProcName), QUOTENAME(@CertName))
                IF (@Verbose = 1)
                    BEGIN
                        SET @Msg = @SQL;
                        RAISERROR(@Msg, 10, 1) WITH NOWAIT;
                    END
                EXEC sp_executesql @SQL;
            END;

            -- Drop existing user & cert
            SELECT @SQL = FORMATMESSAGE(@DropUser, QUOTENAME(@CertUser))
            IF (@Verbose = 1)
                BEGIN
                    SET @Msg = @SQL;
                    RAISERROR(@Msg, 10, 1) WITH NOWAIT;
                END
            EXEC sp_executesql @SQL;

            SELECT @SQL = FORMATMESSAGE(@DropCert, QUOTENAME(@CertName))
            IF (@Verbose = 1)
                BEGIN
                    SET @Msg = @SQL;
                    RAISERROR(@Msg, 10, 1) WITH NOWAIT;
                END
            EXEC sp_executesql @SQL;
        END;

        -- Create new cert
        SELECT @SQL = FORMATMESSAGE(@CreateCert, QUOTENAME(@CertName), @Rando, @StoredProcName)
        IF (@Verbose = 1)
            BEGIN
                SET @Msg = REPLACE(@SQL, @Rando, 'xxxxx');
                RAISERROR(@Msg, 10, 1) WITH NOWAIT;
            END
        EXEC sp_executesql @SQL;

        -- Sign stored proc with cert
        SELECT @SQL = FORMATMESSAGE(@AddSig, QUOTENAME(@SchemaName), QUOTENAME(@StoredProcName), QUOTENAME(@CertName), @Rando)
        IF (@Verbose = 1)
            BEGIN
                SET @Msg = REPLACE(@SQL, @Rando, 'xxxxx');
                RAISERROR(@Msg, 10, 1) WITH NOWAIT;
            END
        EXEC sp_executesql @SQL;

        -- Private key not needed, cover our tracks
        SELECT @SQL = FORMATMESSAGE(@AlterCert, QUOTENAME(@CertName));
        IF (@Verbose = 1)
            BEGIN
                SET @Msg = @SQL;
                RAISERROR(@Msg, 10, 1) WITH NOWAIT;
            END
        EXEC sp_executesql @SQL;

        IF (@TargetDatabaseName IS NOT NULL)
        BEGIN
            -- Import cert and create user in another database
            DECLARE @CertID INT = CERT_ID(QUOTENAME(@CertName));
            DECLARE @PublicKey VARBINARY(MAX) = CERTENCODED(@CertID);
            DECLARE @TargetDatabaseCertName SYSNAME = CONCAT('SIGN ', DB_NAME(), '.', @SchemaName, '.', @StoredProcName);
            SELECT @CertUser = CONCAT(@TargetDatabaseCertName, '$CertUser')

            -- Create cert
            SELECT @SQL = CONCAT('USE ', QUOTENAME(@TargetDatabaseName), ' ;',
            'IF EXISTS (SELECT 1 FROM sys.certificates c WHERE QUOTENAME(c.name) = ''', @TargetDatabaseCertName, '''
            BEGIN
                ', FORMATMESSAGE(@DropUser, QUOTENAME(@CertUser)), '
                ', FORMATMESSAGE(@DropCert, QUOTENAME(@TargetDatabaseCertName)), '
            END');
            IF (@Verbose = 1)
                BEGIN
                    SET @Msg = @SQL;
                    RAISERROR(@Msg, 10, 1) WITH NOWAIT;
                END
            EXEC sp_executesql @SQL;

            SELECT @SQL = CONCAT('USE ', QUOTENAME(@TargetDatabaseName), ';', FORMATMESSAGE(@CreateCertBin, QUOTENAME(@TargetDatabaseCertName), CONVERT(VARCHAR(MAX), @PublicKey, 1)))
            IF (@Verbose = 1)
                BEGIN
                    SET @Msg = REPLACE(@SQL, CONVERT(VARCHAR(MAX), @PublicKey, 1), 'xxxxx');
                    RAISERROR(@Msg, 10, 1) WITH NOWAIT;
                END
            EXEC sp_executesql @SQL;

            -- Create cert based user
            SELECT @SQL = CONCAT('USE ', QUOTENAME(@TargetDatabaseName), ';', FORMATMESSAGE(@CreateUser, QUOTENAME(@CertUser), QUOTENAME(@TargetDatabaseCertName)));
            IF (@Verbose = 1)
                BEGIN
                    SET @Msg = @SQL;
                    RAISERROR(@Msg, 10, 1) WITH NOWAIT;
                END
            EXEC sp_executesql @SQL;

            -- Grant permission to cert
            SELECT @SQL = CONCAT('USE ', QUOTENAME(@TargetDatabaseName), ';',
            'GRANT ', @Permission, ' TO ', QUOTENAME(@CertUser), ';');
            IF (@Verbose = 1)
                BEGIN
                    SET @Msg = @SQL;
                    RAISERROR(@Msg, 10, 1) WITH NOWAIT;
                END
            EXEC sp_executesql @SQL;
        END;
        ELSE
        BEGIN
            -- Create cert based user
            SELECT @SQL = FORMATMESSAGE(@CreateUser, QUOTENAME(@CertUser), QUOTENAME(@CertName))
            IF (@Verbose = 1)
                BEGIN
                    SET @Msg = @SQL;
                    RAISERROR(@Msg, 10, 1) WITH NOWAIT;
                END
            EXEC sp_executesql @SQL;

            -- Grant permissions to cert in same database
            SELECT @SQL = CONCAT('GRANT ', @Permission, ' TO ', QUOTENAME(@CertUser), ';');
            IF (@Verbose = 1)
                BEGIN
                    SET @Msg = @SQL;
                    RAISERROR(@Msg, 10, 1) WITH NOWAIT;
                END
            EXEC sp_executesql @SQL;
        END
    END TRY
    BEGIN CATCH
        SELECT @Msg = FORMATMESSAGE('%s: %s Try troubleshooting: http://dba.stackexchange.com/search?q=msg+%i', OBJECT_NAME(@@PROCID),ERROR_MESSAGE(),ERROR_NUMBER());
        RAISERROR(@Msg, 16, 1) WITH NOWAIT;
    END CATCH;
END;

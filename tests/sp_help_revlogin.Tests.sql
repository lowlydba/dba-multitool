SET NOCOUNT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;

EXEC tSQLt.DropClass 'sp_help_revlogin';
GO

EXEC tSQLt.NewTestClass 'sp_help_revlogin';
GO

CREATE PROCEDURE [sp_help_revlogin].[test sp_help_revlogin returns missing login]
AS
BEGIN;

DECLARE @StartId INT = ISNULL((SELECT MAX([id]) FROM tSQLt.CaptureOutputLog), 0);
DECLARE @Command NVARCHAR(MAX) =
	N'EXEC dbo.sp_help_revlogin @login_name = N''DbaMultitoolMissingLogin'';';

EXEC tSQLt.CaptureOutput @Command;

IF NOT EXISTS (
	SELECT 1
	FROM tSQLt.CaptureOutputLog
	WHERE [id] > @StartId
		AND [OutputText] LIKE '%No login(s) found.%')
	BEGIN;
		EXEC tSQLt.Fail 'sp_help_revlogin did not report the missing login.';
	END;

END;
GO

CREATE PROCEDURE [sp_help_revlogin].[test sp_help_revlogin scripts SQL login]
AS
BEGIN;

DECLARE @LoginName SYSNAME = N'DbaMultitoolRevloginTest';
DECLARE @Command NVARCHAR(MAX);
DECLARE @ExpectedPasswordPolicy VARCHAR(20) = 'CHECK_POLICY = OFF';
DECLARE @ExpectedExpiration VARCHAR(25) = 'CHECK_EXPIRATION = OFF';
DECLARE @StartId INT = ISNULL((SELECT MAX([id]) FROM tSQLt.CaptureOutputLog), 0);

CREATE LOGIN [DbaMultitoolRevloginTest]
WITH PASSWORD = N'P@ssw0rd-Revlogin-2026'
	,DEFAULT_DATABASE = [master]
	,CHECK_POLICY = OFF
	,CHECK_EXPIRATION = OFF;

ALTER LOGIN [DbaMultitoolRevloginTest] DISABLE;
EXEC [master].[sys].[sp_executesql]
	N'DENY CONNECT SQL TO [DbaMultitoolRevloginTest];';
EXEC [master].[sys].[sp_executesql]
	N'ALTER SERVER ROLE [serveradmin] ADD MEMBER [DbaMultitoolRevloginTest];';

SET @Command = N'EXEC dbo.sp_help_revlogin @login_name = N''' + @LoginName + N''';';
EXEC tSQLt.CaptureOutput @Command;

IF NOT EXISTS (
	SELECT 1
	FROM tSQLt.CaptureOutputLog
	WHERE [id] > @StartId
		AND [OutputText] LIKE '%-- Login: ' + @LoginName + '%'
	)
	OR NOT EXISTS (
		SELECT 1
		FROM tSQLt.CaptureOutputLog
		WHERE [id] > @StartId
			AND [OutputText] LIKE '%CREATE LOGIN [DbaMultitoolRevloginTest] WITH PASSWORD = 0x%'
			AND [OutputText] LIKE '% HASHED, SID = 0x%'
			AND [OutputText] LIKE '%' + @ExpectedPasswordPolicy + '%'
			AND [OutputText] LIKE '%' + @ExpectedExpiration + '%'
			AND [OutputText] LIKE '%DENY CONNECT SQL TO [DbaMultitoolRevloginTest]%'
			AND [OutputText] LIKE '%ALTER LOGIN [DbaMultitoolRevloginTest] DISABLE%')
	OR NOT EXISTS (
		SELECT 1
		FROM tSQLt.CaptureOutputLog
		WHERE [id] > @StartId
			AND [OutputText] LIKE '%@rolename=''serveradmin''%')
	BEGIN;
		EXEC tSQLt.Fail 'sp_help_revlogin did not generate the complete SQL login script.';
	END;

END;
GO

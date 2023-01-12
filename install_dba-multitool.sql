SET NOCOUNT OFF;
SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

IF  EXISTS (SELECT * FROM sys.fn_listextendedproperty(N'Description' , N'SCHEMA',N'dbo', N'PROCEDURE',N'sp_doc', NULL,NULL))
	BEGIN;
		EXEC sys.sp_dropextendedproperty @name=N'Description' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'sp_doc';
	END
GO

IF  EXISTS (SELECT * FROM sys.fn_listextendedproperty(N'@SqlMinorVersion' , N'SCHEMA',N'dbo', N'PROCEDURE',N'sp_doc', NULL,NULL))
	BEGIN;
		EXEC sys.sp_dropextendedproperty @name=N'@SqlMinorVersion' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'sp_doc';
	END
GO

IF  EXISTS (SELECT * FROM sys.fn_listextendedproperty(N'@SqlMajorVersion' , N'SCHEMA',N'dbo', N'PROCEDURE',N'sp_doc', NULL,NULL))
	BEGIN;
		EXEC sys.sp_dropextendedproperty @name=N'@SqlMajorVersion' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'sp_doc';
	END
GO

IF  EXISTS (SELECT * FROM sys.fn_listextendedproperty(N'@ExtendedPropertyName' , N'SCHEMA',N'dbo', N'PROCEDURE',N'sp_doc', NULL,NULL))
	BEGIN;
		EXEC sys.sp_dropextendedproperty @name=N'@ExtendedPropertyName' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'sp_doc';
	END
GO

IF  EXISTS (SELECT * FROM sys.fn_listextendedproperty(N'@DatabaseName' , N'SCHEMA',N'dbo', N'PROCEDURE',N'sp_doc', NULL,NULL))
	BEGIN;
		EXEC sys.sp_dropextendedproperty @name=N'@DatabaseName' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'sp_doc';
	END
GO

IF  EXISTS (SELECT * FROM sys.fn_listextendedproperty(N'@LimitStoredProcLength' , N'SCHEMA',N'dbo', N'PROCEDURE',N'sp_doc', NULL,NULL))
	BEGIN;
		EXEC sys.sp_dropextendedproperty @name=N'@LimitStoredProcLength' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'sp_doc';
	END
GO

IF  EXISTS (SELECT * FROM sys.fn_listextendedproperty(N'@Emojis' , N'SCHEMA',N'dbo', N'PROCEDURE',N'sp_doc', NULL,NULL))
	BEGIN;
		EXEC sys.sp_dropextendedproperty @name=N'@Emojis' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'sp_doc';
	END
GO

IF  EXISTS (SELECT * FROM sys.fn_listextendedproperty(N'@Verbose' , N'SCHEMA',N'dbo', N'PROCEDURE',N'sp_doc', NULL,NULL))
	BEGIN;
		EXEC sys.sp_dropextendedproperty @name=N'@Verbose' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'sp_doc';
	END
GO

IF  EXISTS (SELECT * FROM sys.fn_listextendedproperty(N'@AllExtendedProperties' , N'SCHEMA',N'dbo', N'PROCEDURE',N'sp_doc', NULL,NULL))
	BEGIN;
		EXEC sys.sp_dropextendedproperty @name=N'@AllExtendedProperties' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'sp_doc';
	END
GO

/***************************/
/* Create stored procedure */
/***************************/
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_doc]') AND [type] IN (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[sp_doc] AS';
END
GO

ALTER PROCEDURE [dbo].[sp_doc]
	@DatabaseName SYSNAME = NULL
	,@ExtendedPropertyName SYSNAME = 'Description'
	,@AllExtendedProperties BIT = 0
	,@LimitStoredProcLength BIT = 1
	,@Emojis BIT = 0
	,@Verbose BIT = 1
	/* Parameters defined here for testing only */
	,@SqlMajorVersion TINYINT = 0
	,@SqlMinorVersion SMALLINT = 0
WITH RECOMPILE
AS

/*
sp_doc - Always have current documentation by generating it on the fly in markdown.

Part of the DBA MultiTool https://dba-multitool.org

Version: 20211223

MIT License

Copyright (c) 2023 John McCall

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

	EXEC sp_doc @DatabaseName = 'WideWorldImporters';

*/

BEGIN

	SET NOCOUNT ON;

	DECLARE @Sql NVARCHAR(MAX)
		,@ParmDefinition NVARCHAR(500)
		,@QuotedDatabaseName SYSNAME
		,@Msg NVARCHAR(MAX)
		,@SensitivityClassification BIT
		-- Escaping markdown inside EP via HTML codes since
		-- we can't traditionally escape unknown content easily
		,@PipeHTMLCode CHAR(6) = '&#124;'
		,@TickHTMLCode CHAR(5) = '&#96;'
		,@RightBracketHTMLCode CHAR(5) = '&#93;'
		,@BreakHTMLCode CHAR(5) = '<br/>'
		-- Variables for Emoji mode
		,@Yes VARCHAR(20) = 'yes'
		,@No VARCHAR(20) = 'no'
		,@PK VARCHAR(20) = NULL
		,@FK VARCHAR(20) = NULL
		,@Column VARCHAR(20) = NULL;

	-- Find Version
	IF (@SqlMajorVersion = 0)
		BEGIN;
			SET @SqlMajorVersion = CAST(SERVERPROPERTY('ProductMajorVersion') AS TINYINT);
		END;
	IF (@SqlMinorVersion = 0)
		BEGIN;
			SET @SqlMinorVersion = CAST(SERVERPROPERTY('ProductMinorVersion') AS TINYINT);
		END;

	-- Validate Version
	IF (@SqlMajorVersion < 11)
		BEGIN;
			SET @Msg = 'SQL Server versions below 2012 are not supported, sorry!';
			RAISERROR(@Msg, 16, 1);
		END;

	-- Check database name
	IF (@DatabaseName IS NULL)
		BEGIN
			SET @DatabaseName = DB_NAME();
			IF (@Verbose = 1)
				BEGIN;
					SET @Msg = 'No database provided, assuming current database.';
					RAISERROR(@Msg, 10, 1) WITH NOWAIT;
				END;
		END
	ELSE IF (DB_ID(@DatabaseName) IS NULL)
		BEGIN;
			SET @Msg = 'Database not available.';
			RAISERROR(@Msg, 16, 1);
		END;

	SET @QuotedDatabaseName = QUOTENAME(@DatabaseName); --Avoid injections

	-- Check Emoji Mode
	IF (@Emojis = 1)
		BEGIN;
			SET @Yes = ':heavy_check_mark:';
			SET @No = ':x:';
			SET @PK = ':key: ';
			SET @FK = ':old_key: ';
			SET @Column = ':page_facing_up: ';
		END;

	-- Check for Sensitivity Classifications
	IF EXISTS (SELECT 1 FROM [sys].[system_views] WHERE [name] = 'sensitivity_classifications')
		BEGIN
			SET @Sql = N'USE ' + @QuotedDatabaseName + ';
				IF EXISTS (SELECT 1 FROM [sys].[sensitivity_classifications])
					BEGIN
						SET @SensitivityClassification = 1;
					END;
				ELSE
					BEGIN
						SET @SensitivityClassification = 0;
					END;';
			SET @ParmDefinition = N'@SensitivityClassification BIT OUTPUT';
			EXEC sp_executesql @Sql
				,@ParmDefinition
				,@SensitivityClassification OUTPUT;
		END;

	--Create table to hold EP data
	SET @Sql = N'USE ' + @QuotedDatabaseName + ';
	CREATE TABLE #markdown (
	   [id] INT IDENTITY(1,1),
	   [value] NVARCHAR(MAX));';

	/******************************
	Generate markdown for database
	******************************/
	--Database Name
	SET @Sql = @Sql + N'
	INSERT INTO #markdown (value)
	VALUES (CONCAT(''# '', @DatabaseName) COLLATE DATABASE_DEFAULT);' +

	--Database extended properties
	+ N'INSERT INTO #markdown (value)
		SELECT CONCAT(CHAR(13), CHAR(10), CAST([value] AS VARCHAR(8000)))
		FROM [sys].[extended_properties] AS [ep]
		WHERE [ep].[class] = 0
			AND [ep].[name] = @ExtendedPropertyName;' +

	--Database metadata
	+ N'INSERT INTO #markdown (value)
		VALUES (CONCAT(CHAR(13), CHAR(10), ''| Property | Value |''))
		,(''| --- | --- |'');

		INSERT INTO #markdown
		SELECT CONCAT(''| '', ''SQL Server Version'', '' | '', CAST(SERVERPROPERTY(''ProductVersion'') AS SYSNAME), '' |'')
		UNION ALL
		SELECT CONCAT(''| '', ''Compatibility Level'', '' | '', [compatibility_level], '' |'')
		FROM [sys].[databases]
		WHERE [name] = DB_NAME()
		UNION ALL
		SELECT CONCAT(''| '', ''Collation'', '' | '', [collation_name], '' |'')
		FROM [sys].[databases]
		WHERE [name] = DB_NAME();

		INSERT INTO #markdown (value)
		VALUES (''----'');' +

	--Variables
	+ N'DECLARE @ObjectId INT,
		@IndexObjectId INT,
		@TrigObjectId INT,
		@CheckConstObjectId INT,
		@DefaultConstObjectId INT;

		DECLARE @KeyColumns NVARCHAR(MAX),
		@IncludeColumns NVARCHAR(MAX);';

	/*****************************
	Generate markdown for schemas
	*****************************/
	--Build table of contents
	SET @Sql = @Sql + N'
	INSERT INTO #markdown (value)
	VALUES (CONCAT(CHAR(13), CHAR(10), ''## Schemas''))
		,(CONCAT(CHAR(13), CHAR(10), ''<details><summary>Click to expand</summary>'', CHAR(13), CHAR(10)));' +

	+ N'INSERT INTO #markdown (value)
	SELECT CONCAT(''* ['', [name], ''](#'', REPLACE(LOWER([name]), '' '', ''-''), '')'')
	FROM [sys].[schemas]
	WHERE [schema_id] < 16384
		AND [name] NOT IN (''sys'', ''guest'', ''INFORMATION_SCHEMA'')
	ORDER BY [name] ASC;' +

	--Object details
	+ N'DECLARE [obj_cursor] CURSOR
	LOCAL STATIC READ_ONLY FORWARD_ONLY
	FOR
	SELECT [schema_id]
	FROM [sys].[schemas]
	WHERE [schema_id] < 16384
		AND [name] NOT IN (''sys'', ''guest'', ''INFORMATION_SCHEMA'')
	ORDER BY [name] ASC;

	OPEN [obj_cursor]
	FETCH NEXT FROM [obj_cursor] INTO @ObjectId
	WHILE @@FETCH_STATUS = 0
	BEGIN;

		INSERT INTO #markdown
		SELECT CONCAT(CHAR(13), CHAR(10), ''### '', SCHEMA_NAME(@ObjectId));' +

		--Main Extended Property (@ExtendedProperty)
		+ N'
		IF EXISTS (SELECT * FROM [sys].[schemas] AS [s] WITH(NOLOCK)
						INNER JOIN [sys].[extended_properties] AS [ep] WITH(NOLOCK) ON [s].[schema_id] = [ep].[major_id]
						WHERE [s].[schema_id] = @ObjectId
							AND [ep].[minor_id] = 0 --On the object
							AND [ep].[class] = 3 --Schema
							AND [ep].[name] = @ExtendedPropertyName)
				BEGIN;
					INSERT INTO #markdown (value)
					VALUES (CONCAT(CHAR(13), CHAR(10), ''| '', @ExtendedPropertyName COLLATE DATABASE_DEFAULT, '' |''))
					,(''| --- |'');

					INSERT INTO #markdown (value)
					SELECT CONCAT(''| '', REPLACE(REPLACE(REPLACE(REPLACE(CAST([ep].[value] AS NVARCHAR(4000)), ''|'', @PipeHTMLCode COLLATE DATABASE_DEFAULT), CHAR(13) + CHAR(10), @BreakHTMLCode COLLATE DATABASE_DEFAULT), ''`'', @TickHTMLCode COLLATE DATABASE_DEFAULT), '']'', @RightBracketHTMLCode COLLATE DATABASE_DEFAULT) COLLATE DATABASE_DEFAULT, '' |'')
					FROM [sys].[schemas] AS [s] WITH(NOLOCK)
						INNER JOIN [sys].[extended_properties] AS [ep] WITH(NOLOCK) ON [s].[schema_id] = [ep].[major_id]
					WHERE [s].[schema_id] = @ObjectId
						AND [ep].[minor_id] = 0 --On the object
						AND [ep].[class] = 3 --Schema
						AND [ep].[name] = @ExtendedPropertyName;
				END;';

		--All Extended Properties (non-@ExtendedProperty)
		IF @AllExtendedProperties = 1
			BEGIN;
				SET @Sql = @Sql + N'
				IF EXISTS (SELECT * FROM [sys].[schemas] AS [s] WITH(NOLOCK)
						INNER JOIN [sys].[extended_properties] AS [ep] WITH(NOLOCK) ON [s].[schema_id] = [ep].[major_id]
						WHERE [s].[schema_id] = @ObjectId
							AND [ep].[minor_id] = 0 --On the object
							AND [ep].[class] = 3 --Schema
							AND [ep].[name] <> @ExtendedPropertyName)
				BEGIN;
					INSERT INTO #markdown (value)
					VALUES (CONCAT(CHAR(13), CHAR(10), ''#### '', ''Extended Properties''))
					,(CONCAT(CHAR(13), CHAR(10), ''| Name | Value |''))
					,(''| --- | --- |'');

					INSERT INTO #markdown (value)
					SELECT CONCAT(''| '', [ep].[name], '' | '', REPLACE(REPLACE(REPLACE(REPLACE(CAST([ep].[value] AS NVARCHAR(4000)), ''|'', @PipeHTMLCode COLLATE DATABASE_DEFAULT), CHAR(13) + CHAR(10), @BreakHTMLCode COLLATE DATABASE_DEFAULT), ''`'', @TickHTMLCode COLLATE DATABASE_DEFAULT), '']'', @RightBracketHTMLCode COLLATE DATABASE_DEFAULT) COLLATE DATABASE_DEFAULT, '' |'')
					FROM [sys].[schemas] AS [s] WITH(NOLOCK)
						INNER JOIN [sys].[extended_properties] AS [ep] WITH(NOLOCK) ON [s].[schema_id] = [ep].[major_id]
					WHERE [s].[schema_id] = @ObjectId
						AND [ep].[minor_id] = 0 --On the object
						AND [ep].[class] = 3 --Schema
						AND [ep].[name] <> @ExtendedPropertyName
					ORDER BY [ep].[name] ASC;
				END;';
			END;

		SET @Sql = @Sql + N'
		FETCH NEXT FROM obj_cursor INTO @ObjectId;

	END;
	CLOSE obj_cursor;
	DEALLOCATE obj_cursor;' +

	--End collapsible schema section
	+ N'INSERT INTO #markdown
	VALUES (CONCAT(CHAR(13), CHAR(10), ''</details>''));';
	--End markdown for schemas

	/****************************
	Generate markdown for tables
	****************************/
	--Build table of contents
	SET @Sql = @Sql + N'
	IF EXISTS (SELECT 1 FROM [sys].[tables] WHERE [type] = ''U'' AND [is_ms_shipped] = 0)
	BEGIN
		INSERT INTO #markdown (value)
		VALUES (CONCAT(CHAR(13), CHAR(10), ''## Tables''))
			,(CONCAT(CHAR(13), CHAR(10), ''<details><summary>Click to expand</summary>'', CHAR(13), CHAR(10)));' +

		+ N'INSERT INTO #markdown (value)
		SELECT CONCAT(''* ['', OBJECT_SCHEMA_NAME([t].[object_id]), ''.'', OBJECT_NAME([t].[object_id]), ''](#'', REPLACE(LOWER(OBJECT_SCHEMA_NAME([t].[object_id])), '' '', ''-''), REPLACE(LOWER(OBJECT_NAME([t].[object_id])), '' '', ''-''), '')'')
		FROM [sys].[tables] [t]
            LEFT JOIN [sys].[extended_properties] [ep] ON [t].[object_id] = [ep].[major_id]
				AND [ep].[minor_id] = 0 --On the table
				AND [ep].[class] = 1    --Object or col
				AND [ep].[name] = ''microsoft_database_tools_support''
		WHERE [t].[type] = ''U''
			AND [t].[is_ms_shipped] = 0
			AND [ep].[name] IS NULL --Exclude SSDT tables
		ORDER BY OBJECT_SCHEMA_NAME([t].[object_id]), [t].[name] ASC;' +

		--Object details
		+ N'DECLARE obj_cursor CURSOR
		LOCAL STATIC READ_ONLY FORWARD_ONLY
		FOR
		SELECT [t].[object_id]
		FROM [sys].[tables] [t]
		    LEFT JOIN [sys].[extended_properties] [ep] ON [t].[object_id] = [ep].[major_id]
				AND [ep].[minor_id] = 0 --On the table
				AND [ep].[class] = 1    --Object or col
				AND [ep].[name] = ''microsoft_database_tools_support''
		WHERE [t].[type] = ''U''
			AND [t].[is_ms_shipped] = 0
			AND [ep].[name] IS NULL --Exclude SSDT tables
		ORDER BY OBJECT_SCHEMA_NAME([t].[object_id]), [t].[name] ASC;

		OPEN obj_cursor
		FETCH NEXT FROM obj_cursor INTO @ObjectId
		WHILE @@FETCH_STATUS = 0
		BEGIN

			INSERT INTO #markdown
			SELECT CONCAT(CHAR(13), CHAR(10), ''### '', OBJECT_SCHEMA_NAME(@ObjectId), ''.'', OBJECT_NAME(@ObjectId));' +

			--Main Extended Property (@ExtendedProperty)
			+ N'
			IF EXISTS (SELECT * FROM [sys].[tables] AS [t] WITH(NOLOCK)
							INNER JOIN [sys].[extended_properties] AS [ep] WITH(NOLOCK) ON [t].[object_id] = [ep].[major_id]
							WHERE [t].[object_id] = @ObjectId
								AND [ep].[minor_id] = 0 --On the table
								AND [ep].[class] = 1 --Object or col
								AND [ep].[name] = @ExtendedPropertyName)
					BEGIN;
						INSERT INTO #markdown (value)
						VALUES (CONCAT(CHAR(13), CHAR(10), ''| '', @ExtendedPropertyName COLLATE DATABASE_DEFAULT, '' |''))
						,(''| --- |'');

						INSERT INTO #markdown (value)
						SELECT CONCAT(''| '', REPLACE(REPLACE(REPLACE(REPLACE(CAST([ep].[value] AS NVARCHAR(4000)), ''|'', @PipeHTMLCode COLLATE DATABASE_DEFAULT), CHAR(13) + CHAR(10), @BreakHTMLCode COLLATE DATABASE_DEFAULT), ''`'', @TickHTMLCode COLLATE DATABASE_DEFAULT), '']'', @RightBracketHTMLCode COLLATE DATABASE_DEFAULT) COLLATE DATABASE_DEFAULT, '' |'')
						FROM [sys].[tables] AS [t] WITH(NOLOCK)
							INNER JOIN [sys].[extended_properties] AS [ep] WITH(NOLOCK) ON [t].[object_id] = [ep].[major_id]
						WHERE [t].[object_id] = @ObjectId
							AND [ep].[minor_id] = 0 --On the table
							AND [ep].[class] = 1 --Object or col
							AND [ep].[name] = @ExtendedPropertyName;
					END;';

			--All Extended Properties (non-@ExtendedProperty)
			IF @AllExtendedProperties = 1
				BEGIN;
					SET @Sql = @Sql + N'
					IF EXISTS (SELECT * FROM [sys].[tables] AS [t] WITH(NOLOCK)
							INNER JOIN [sys].[extended_properties] AS [ep] WITH(NOLOCK) ON [t].[object_id] = [ep].[major_id]
							WHERE [t].[object_id] = @ObjectId
								AND [ep].[minor_id] = 0 --On the table
								AND [ep].[class] = 1 --Object or col
								AND [ep].[name] <> @ExtendedPropertyName)
					BEGIN;
						INSERT INTO #markdown (value)
						VALUES (CONCAT(CHAR(13), CHAR(10), ''#### '', ''Extended Properties''))
						,(CONCAT(CHAR(13), CHAR(10), ''| Name | Value |''))
						,(''| --- | --- |'');

						INSERT INTO #markdown (value)
						SELECT CONCAT(''| '', [ep].[name], '' | '', REPLACE(REPLACE(REPLACE(REPLACE(CAST([ep].[value] AS NVARCHAR(4000)), ''|'', @PipeHTMLCode COLLATE DATABASE_DEFAULT), CHAR(13) + CHAR(10), @BreakHTMLCode COLLATE DATABASE_DEFAULT), ''`'', @TickHTMLCode COLLATE DATABASE_DEFAULT), '']'', @RightBracketHTMLCode COLLATE DATABASE_DEFAULT) COLLATE DATABASE_DEFAULT, '' |'')
						FROM [sys].[tables] AS [t] WITH(NOLOCK)
							INNER JOIN [sys].[extended_properties] AS [ep] WITH(NOLOCK) ON [t].[object_id] = [ep].[major_id]
						WHERE [t].[object_id] = @ObjectId
							AND [ep].[minor_id] = 0 --On the table
							AND [ep].[class] = 1 --Object or col
							AND [ep].[name] <> @ExtendedPropertyName
						ORDER BY [ep].[name] ASC;
					END;';
				END;

			-- Columns
			SET @Sql = @Sql + N'
			INSERT INTO #markdown (value)
			SELECT CONCAT(CHAR(13), CHAR(10), ''#### '', ''Columns'');';

			IF @SensitivityClassification = 1
				BEGIN;
					SET @Sql = @Sql + N'
					INSERT INTO #markdown (value)
					VALUES (CONCAT(CHAR(13), CHAR(10), ''| Column | Type | Null | Foreign Key | Default | '', @ExtendedPropertyName COLLATE DATABASE_DEFAULT, '' | Classification |''))
					,(''| --- | --- | --- | --- | --- | --- | --- |'');';
				END;
			ELSE
				BEGIN
				SET @Sql = @Sql + N'
					INSERT INTO #markdown (value)
					VALUES (CONCAT(CHAR(13), CHAR(10), ''| Column | Type | Null | Foreign Key | Default | '', @ExtendedPropertyName COLLATE DATABASE_DEFAULT, '' |''))
					,(''| --- | --- | --- | --- | --- | --- |'');';
				END;

			--Columns
			SET @Sql = @Sql + N'
			INSERT INTO #markdown (value)
			SELECT CONCAT(''| ''
                    ,CASE
                        WHEN [ic].[object_id] IS NOT NULL
                        THEN CONCAT(@PK, ''**'',[c].[name],''**'')
						WHEN [fk].[parent_object_id] IS NOT NULL
						THEN CONCAT(@FK, [c].[name])
                        ELSE CONCAT(@Column, [c].[name])
                    END
					,'' | ''
					,CONCAT(UPPER(TYPE_NAME([user_type_id]))
					,CASE
							WHEN TYPE_NAME([user_type_id]) IN (N''decimal'',N''numeric'')
							THEN CONCAT(N''('',CAST(precision AS varchar(5)), N'','',CAST(scale AS varchar(5)), N'')'')
							WHEN TYPE_NAME([user_type_id]) IN (''varchar'', ''char'', ''varbinary'')
							THEN CASE
									WHEN [max_length] = -1
									THEN N''(MAX)''
									ELSE QUOTENAME(CAST([max_length] AS VARCHAR(10)), ''('')
								END
							WHEN TYPE_NAME([user_type_id]) IN (N''time'',N''datetime2'',N''datetimeoffset'')
							THEN QUOTENAME(CAST(scale AS varchar(5)), ''('')
							WHEN TYPE_NAME([user_type_id]) in (N''float'')
							THEN CASE
									WHEN [c].precision = 53
									THEN N''''
									ELSE CONCAT(N''('',CAST([c].precision AS varchar(5)),N'')'')
								END
							WHEN TYPE_NAME([c].user_type_id) IN (N''int'',N''bigint'',N''smallint'',N''tinyint'',N''money'',N''smallmoney'',
								N''real'',N''datetime'',N''smalldatetime'',N''bit'',N''image'',N''text'',N''uniqueidentifier'',
								N''date'',N''ntext'',N''sql_variant'',N''hierarchyid'',''geography'',N''timestamp'',N''xml'')
							THEN N''''
							WHEN TYPE_NAME([user_type_id]) IN (N''nvarchar'',N''nchar'', N''sysname'')
							THEN CASE
									WHEN [max_length] = -1
									THEN N''(MAX)''
									ELSE QUOTENAME(CAST([max_length]/2 AS VARCHAR(10)), ''('')
								END
							ELSE QUOTENAME(CAST([max_length] AS VARCHAR(10)), ''('')
					END)
					,'' | ''
					,CASE [c].[is_nullable]
						WHEN 1
						THEN @Yes
						ELSE @No
						END
					,'' | ''
					,CASE
						WHEN [fk].[parent_object_id] IS NOT NULL
						THEN CONCAT(''['',QUOTENAME(OBJECT_SCHEMA_NAME([fk].[referenced_object_id])), ''.'', QUOTENAME(OBJECT_NAME([fk].[referenced_object_id])), ''.'', QUOTENAME(COL_NAME([fk].[referenced_object_id], [fk].[referenced_column_id])),'']'',''(#'',LOWER(OBJECT_SCHEMA_NAME([fk].[referenced_object_id])), LOWER(OBJECT_NAME([fk].[referenced_object_id])), '')'')
						ELSE ''''
                    END
					,'' | ''
					,OBJECT_DEFINITION([dc].[object_id])
					,'' | ''
					,REPLACE(REPLACE(REPLACE(REPLACE(CAST([ep].[value] AS NVARCHAR(4000)), ''|'', @PipeHTMLCode COLLATE DATABASE_DEFAULT), CHAR(13) + CHAR(10), @BreakHTMLCode COLLATE DATABASE_DEFAULT), ''`'', @TickHTMLCode COLLATE DATABASE_DEFAULT), '']'', @RightBracketHTMLCode COLLATE DATABASE_DEFAULT) COLLATE DATABASE_DEFAULT
					,'' |''';
					IF @SensitivityClassification = 1
						BEGIN
							SET @Sql = @Sql + N'
							,CASE
								WHEN [sc].[label] IS NOT NULL
								THEN CONCAT('' Label: '', CAST([sc].[Label] AS SYSNAME), '' <br /> '', ''Type: '', CAST([sc].[Information_Type] AS SYSNAME), '' <br /> '', ''Rank: '', CAST([Rank_Desc] AS SYSNAME), '' <br /> '')
								ELSE '' ''
							END
							,'' |''';
						END
					SET @Sql = @Sql + N')';
			SET @Sql = @Sql + N'
			FROM [sys].[tables] AS [t] WITH(NOLOCK)
				INNER JOIN [sys].[columns] AS [c] WITH(NOLOCK) ON [t].[object_id] = [c].[object_id]
				LEFT JOIN [sys].[extended_properties] AS [ep] WITH(NOLOCK) ON [t].[object_id] = [ep].[major_id]
					AND [ep].[minor_id] > 0
					AND [ep].[minor_id] = [c].[column_id]
					AND [ep].[class] = 1 --Object/col
					AND [ep].[name] = @ExtendedPropertyName
				LEFT JOIN [sys].[foreign_key_columns] AS [fk] WITH(NOLOCK) ON [fk].[parent_object_id] = [c].[object_id]
					AND [fk].[parent_column_id] = [c].[column_id]
				LEFT JOIN [sys].[default_constraints] AS [dc] WITH(NOLOCK) ON [dc].[parent_object_id] = [c].[object_id]
					AND [dc].[parent_column_id] = [c].[column_id]
				LEFT JOIN [sys].[indexes] AS [pk] WITH(NOLOCK) ON [pk].[object_id] = [t].[object_id]
					AND [pk].[is_primary_key] = 1
				LEFT JOIN [sys].[index_columns] AS [ic] WITH(NOLOCK) ON [ic].[index_id] = [pk].[index_id]
					AND [ic].[object_id] = [t].[object_id]
					AND [ic].[column_id] = [c].[column_id]';

			IF @SensitivityClassification = 1
				BEGIN
					SET @Sql = @Sql + N'
				LEFT JOIN [sys].[sensitivity_classifications] AS [sc] WITH(NOLOCK) ON [sc].[major_id] = [t].[object_id]
					AND [sc].[minor_id] = [c].[column_id]';
				END;

			SET @Sql = @Sql + N'
			WHERE [t].[object_id] = @ObjectId;';

			--Column Extended Properties
			IF @AllExtendedProperties = 1
				BEGIN
					SET @Sql = @Sql + N'
					IF EXISTS (SELECT * FROM [sys].[tables] AS [t] WITH(NOLOCK)
							INNER JOIN [sys].[extended_properties] AS [ep] WITH(NOLOCK) ON [t].[object_id] = [ep].[major_id]
							WHERE [t].[object_id] = @ObjectId
								AND [ep].[minor_id] > 0 --Column, when class = 1
								AND [ep].[class] = 1 --Object/col
								AND [ep].[name] <> @ExtendedPropertyName)
					BEGIN
						INSERT INTO #markdown (value)
						VALUES (CONCAT(CHAR(13), CHAR(10), ''##### '', ''Column Extended Properties''))
						,(CONCAT(CHAR(13), CHAR(10), ''Column | Name | Value |''))
						,(''| --- | --- | --- |'');

						INSERT INTO #markdown (value)
						SELECT CONCAT(''| '', [c].[name], '' | '', [ep].[name], '' | '', REPLACE(REPLACE(REPLACE(REPLACE(CAST([ep].[value] AS NVARCHAR(4000)), ''|'', @PipeHTMLCode COLLATE DATABASE_DEFAULT), CHAR(13) + CHAR(10), @BreakHTMLCode COLLATE DATABASE_DEFAULT), ''`'', @TickHTMLCode COLLATE DATABASE_DEFAULT), '']'', @RightBracketHTMLCode COLLATE DATABASE_DEFAULT) COLLATE DATABASE_DEFAULT, '' |'')
						FROM [sys].[tables] AS [t] WITH(NOLOCK)
							INNER JOIN [sys].[extended_properties] AS [ep] WITH(NOLOCK) ON [t].[object_id] = [ep].[major_id]
							INNER JOIN [sys].[columns] AS [c] ON [ep].[minor_id] = [c].[column_id]
								AND [c].[object_id] = [t].[object_id]
						WHERE [t].[object_id] = @ObjectId
							AND [ep].[minor_id] > 0 --Column (when class = 1)
							AND [ep].[class] = 1 --Object/col
							AND [ep].[name] <> @ExtendedPropertyName
						ORDER BY [c].[name], [ep].[name] ASC;
					END;';
				END

			--Indexes
			SET @Sql = @Sql + N'
			IF EXISTS (SELECT 1 FROM [sys].[indexes] WHERE [object_id] = @ObjectId AND [type] > 0)
			BEGIN
				INSERT INTO #markdown (value)
				SELECT CONCAT(CHAR(13), CHAR(10), ''#### '', ''Indexes'');
				DECLARE [index_cursor] CURSOR
				LOCAL STATIC READ_ONLY FORWARD_ONLY
				FOR
				SELECT [ind].[index_id]
				FROM [sys].[indexes] AS [ind]
				WHERE [ind].[object_id] = @ObjectId
					AND [ind].[type] > 0 -- Not heap
				ORDER BY [ind].[is_primary_key] DESC, [ind].[is_unique_constraint] DESC, [ind].[name] DESC

				INSERT INTO #markdown (value)
					VALUES (CONCAT(CHAR(13), CHAR(10), ''| Name | Type | Key Columns | Include Columns | '', @ExtendedPropertyName COLLATE DATABASE_DEFAULT, '' |''))
					,(''| --- | --- | --- | --- | --- |'');

				OPEN [index_cursor]
				FETCH NEXT FROM [index_cursor] INTO @IndexObjectId
				WHILE @@FETCH_STATUS = 0
				BEGIN
				' +

					-- Get key columns as a csv list
					+ N'SELECT @KeyColumns = STUFF((
							SELECT CONCAT('', '', QUOTENAME([col].[name]))
							FROM [sys].[indexes] AS [ind]
								INNER JOIN [sys].[index_columns] AS [ic] ON [ind].[object_id] = [ic].[object_id]
									AND [ic].[index_id] = [ind].[index_id]
								INNER JOIN [sys].[columns] AS [col] ON [ic].[object_id] = [col].[object_id]
									AND [ic].[column_id] = [col].[column_id]
							WHERE [ind].[object_id] = @ObjectId
								AND [ind].[index_id] = @IndexObjectId
								AND [ic].[is_included_column] = 0
							FOR XML PATH('''')
						), 1, 2, ''''); ' +

					-- Get included columns as a csv list
					+ N'SELECT @IncludeColumns = STUFF((
							SELECT CONCAT('', '', QUOTENAME([col].[name]))
							FROM [sys].[indexes] AS [ind]
								INNER JOIN [sys].[index_columns] AS [ic] ON [ind].[object_id] = [ic].[object_id]
									AND [ic].[index_id] = [ind].[index_id]
								INNER JOIN [sys].[columns] AS [col] ON [ic].[object_id] = [col].[object_id]
									AND [ic].[column_id] = [col].[column_id]
							WHERE [ind].[object_id] = @ObjectId
								AND [ind].[index_id] = @IndexObjectId
								AND [ic].[is_included_column] = 1
							FOR XML PATH('''')
						), 1, 2, '''');

					INSERT INTO #markdown (value)
					SELECT CONCAT(''| ''
						,CASE
							WHEN [ind].[is_primary_key] = 1
                        	THEN CONCAT(@PK, ''**'',[ind].[name],''**'')
							ELSE [ind].[name]
						END
						, '' | ''
						, LOWER([ind].[type_desc]) COLLATE DATABASE_DEFAULT
						, '' | ''
						, @KeyColumns COLLATE DATABASE_DEFAULT
						, '' | ''
						, @IncludeColumns COLLATE DATABASE_DEFAULT
						, '' | ''
						, REPLACE(REPLACE(REPLACE(REPLACE(CAST([ep].[value] AS NVARCHAR(4000)), ''|'', @PipeHTMLCode COLLATE DATABASE_DEFAULT), CHAR(13) + CHAR(10), @BreakHTMLCode COLLATE DATABASE_DEFAULT), ''`'', @TickHTMLCode COLLATE DATABASE_DEFAULT), '']'', @RightBracketHTMLCode COLLATE DATABASE_DEFAULT) COLLATE DATABASE_DEFAULT
						, '' |'')
					FROM [sys].[indexes] AS [ind]
						LEFT JOIN [sys].[extended_properties] AS [ep] ON [ind].[object_id] = [ep].[major_id]
							AND [ep].[minor_id] = [ind].[index_id]
							AND [ep].[class] = 7 -- Index
							AND [ep].[name] = @ExtendedPropertyName
					WHERE [ind].[object_id] = @ObjectId
						AND [ind].[index_id] = @IndexObjectId;

					FETCH NEXT FROM [index_cursor] INTO @IndexObjectId;
				END;

				CLOSE [index_cursor];
				DEALLOCATE [index_cursor];
			END;
			';

			--Index Extended Properties
			IF @AllExtendedProperties = 1
				BEGIN;
					SET @Sql = @Sql + N'
					IF EXISTS (SELECT * FROM [sys].[indexes] AS [ind]
											INNER JOIN [sys].[extended_properties] AS [ep] ON [ind].[object_id] = [ep].[major_id]
												AND [ep].[minor_id] = [ind].[index_id]
												AND [ep].[class] = 7 -- Index
										WHERE [ind].[object_id] = @ObjectId
										AND [ind].[index_id] = @IndexObjectId
										AND [ep].[name] <> @ExtendedPropertyName)
					BEGIN
						INSERT INTO #markdown (value)
						VALUES (CONCAT(CHAR(13), CHAR(10), ''##### '', ''Index Extended Properties''))
						,(CONCAT(CHAR(13), CHAR(10), ''Index | Name | Value |''))
						,(''| --- | --- | --- |'');

						INSERT INTO #markdown (value)
						SELECT CONCAT(''| '', [ind].[name], '' | '', [ep].[name], '' | '', REPLACE(REPLACE(REPLACE(REPLACE(CAST([ep].[value] AS NVARCHAR(4000)), ''|'', @PipeHTMLCode COLLATE DATABASE_DEFAULT), CHAR(13) + CHAR(10), @BreakHTMLCode COLLATE DATABASE_DEFAULT), ''`'', @TickHTMLCode COLLATE DATABASE_DEFAULT), '']'', @RightBracketHTMLCode COLLATE DATABASE_DEFAULT) COLLATE DATABASE_DEFAULT, '' |'')
						FROM [sys].[indexes] AS [ind]
							LEFT JOIN [sys].[extended_properties] AS [ep] ON [ind].[object_id] = [ep].[major_id]
								AND [ep].[minor_id] = [ind].[index_id]
								AND [ep].[class] = 7 -- Index
						WHERE [ind].[object_id] = @ObjectId
							AND [ind].[index_id] = @IndexObjectId
							AND [ep].[name] <> @ExtendedPropertyName
						ORDER BY [ind].[name], [ep].[name] ASC;
					END;';
				END;

			--Triggers
			SET @Sql = @Sql + N'
			IF EXISTS (SELECT * FROM [sys].[triggers] WHERE [parent_id] = @ObjectId)
			BEGIN
				INSERT INTO #markdown (value)
				SELECT CONCAT(CHAR(13), CHAR(10), ''#### '', ''Triggers'')
				DECLARE [trig_cursor] CURSOR
				LOCAL STATIC READ_ONLY FORWARD_ONLY
				FOR
				SELECT [object_id]
				FROM [sys].[triggers]
				WHERE [parent_id] = @ObjectId
				ORDER BY OBJECT_SCHEMA_NAME([object_id]), [name] ASC;

				OPEN [trig_cursor]
				FETCH NEXT FROM [trig_cursor] INTO @TrigObjectId
				WHILE @@FETCH_STATUS = 0
				BEGIN
					INSERT INTO #markdown (value)
					VALUES (CONCAT(''##### '', OBJECT_SCHEMA_NAME(@TrigObjectId), ''.'', OBJECT_NAME(@TrigObjectId)))
						,(CONCAT(''###### '', ''Definition''))
						,(CONCAT(''<details><summary>Click to expand</summary>'', CHAR(13), CHAR(10)));' +

					--Object definition
					+ N'INSERT INTO #markdown (value)
					VALUES (CONCAT(CHAR(13), CHAR(10), ''```sql'',
						CHAR(13), CHAR(10), OBJECT_DEFINITION(@CheckConstObjectId)))
						,(''```'')
						,(CONCAT(CHAR(13), CHAR(10), ''</details>''))

					FETCH NEXT FROM [trig_cursor] INTO @TrigObjectId;
				END;

				CLOSE [trig_cursor];
				DEALLOCATE [trig_cursor];
			END;' +

			--Check Constraints
			+ N'IF EXISTS (SELECT 1 FROM [sys].[check_constraints] WHERE [parent_object_id] = @ObjectId)
			BEGIN
				INSERT INTO #markdown (value)
				SELECT CONCAT(CHAR(13), CHAR(10), ''#### '', ''Check Constraints'');
				DECLARE [check_cursor] CURSOR
				LOCAL STATIC READ_ONLY FORWARD_ONLY
				FOR
				SELECT [object_id]
				FROM [sys].[check_constraints]
				WHERE [parent_object_id] = @ObjectId
				ORDER BY OBJECT_SCHEMA_NAME(object_id), [name] ASC;

				OPEN [check_cursor]
				FETCH NEXT FROM [check_cursor] INTO @CheckConstObjectId
				WHILE @@FETCH_STATUS = 0
				BEGIN
					INSERT INTO #markdown (value)
					VALUES (CONCAT(CHAR(13), CHAR(10),''##### '', OBJECT_SCHEMA_NAME(@CheckConstObjectId), ''.'', OBJECT_NAME(@CheckConstObjectId)))
						,(CONCAT(CHAR(13), CHAR(10),''###### '', ''Definition''))
						,(CONCAT(CHAR(13), CHAR(10),''<details><summary>Click to expand</summary>''));' +

					--Object definition
					+ N'INSERT INTO #markdown (value)
					VALUES (CONCAT(CHAR(13), CHAR(10), ''```sql'',
						CHAR(13), CHAR(10), OBJECT_DEFINITION(@CheckConstObjectId)))
						,(''```'')
						,(CONCAT(CHAR(13), CHAR(10), ''</details>''))

					FETCH NEXT FROM [check_cursor] INTO @CheckConstObjectId;
				END;

				CLOSE [check_cursor];
				DEALLOCATE [check_cursor];
			END;' +

			--Dependencies
			+ N'IF EXISTS (SELECT 1 FROM [sys].[dm_sql_referencing_entities] (CONCAT(OBJECT_SCHEMA_NAME(@ObjectId), ''.'', OBJECT_NAME(@ObjectId)), ''OBJECT''))
					OR EXISTS (SELECT 1 FROM [sys].[foreign_keys] WHERE [referenced_object_id] = @ObjectId)
			BEGIN
				INSERT INTO #markdown (value)
				SELECT CONCAT(CHAR(13), CHAR(10), ''#### '', ''Referenced By'');

				INSERT INTO #markdown (value)
				VALUES (CONCAT(CHAR(13), CHAR(10), ''| Object | Type |''))
					,(''| --- | --- |'');

				INSERT INTO #markdown (value)
				SELECT CONCAT(''| ''
						, CONCAT(''['',QUOTENAME([ref].[referencing_schema_name]), ''.'', QUOTENAME([ref].[referencing_entity_name]),'']'',''(#'',LOWER([ref].[referencing_schema_name]), LOWER([ref].[referencing_entity_name]), '')'')
						,'' | ''
						, REPLACE(LOWER([o].[type_desc]), ''_'' COLLATE DATABASE_DEFAULT, '' '' COLLATE DATABASE_DEFAULT)
						, '' |'') COLLATE DATABASE_DEFAULT
				FROM [sys].[dm_sql_referencing_entities] (CONCAT(OBJECT_SCHEMA_NAME(@ObjectId), ''.'', OBJECT_NAME(@ObjectId)), ''OBJECT'') [ref]
				INNER JOIN [sys].[objects] [o] on [o].[object_id] = [ref].[referencing_id]
				WHERE [ref].[referencing_id] <> @ObjectId -- Exclude self-references
				UNION ALL
				SELECT CONCAT(''| ''
						,CONCAT(''['',QUOTENAME(SCHEMA_NAME([fk].[schema_id])), ''.'', QUOTENAME(OBJECT_NAME([fk].[parent_object_id])), ''.'', QUOTENAME([fk].[name]), '']'',''(#'',LOWER(SCHEMA_NAME([fk].[schema_id])), LOWER(OBJECT_NAME([fk].[parent_object_id])), '')'')
						,'' | ''
						,REPLACE(LOWER([fk].[type_desc]), ''_'' COLLATE DATABASE_DEFAULT, '' '' COLLATE DATABASE_DEFAULT)
						,'' |'') COLLATE DATABASE_DEFAULT
				FROM [sys].[foreign_keys] [fk]
				WHERE [fk].[referenced_object_id] = @ObjectId
				ORDER BY 1;
			END;' +

			--Back to top
			+ N'INSERT INTO #markdown
			VALUES (CONCAT(CHAR(13), CHAR(10), ''[Back to top](#'', LOWER(@DatabaseName COLLATE DATABASE_DEFAULT), '')''));

			FETCH NEXT FROM obj_cursor INTO @ObjectId;

		END;
		CLOSE obj_cursor;
		DEALLOCATE obj_cursor;' +

		--End collapsible table section
		+ N'INSERT INTO #markdown
		VALUES (CONCAT(CHAR(13), CHAR(10), ''</details>''));
	END;'; --End markdown for tables

	/***************************
	Generate markdown for views
	***************************/
	--Build table of contents
	SET @Sql = @Sql + N'
	IF EXISTS (SELECT 1 FROM [sys].[views] WHERE [is_ms_shipped] = 0)
	BEGIN;
		INSERT INTO #markdown (value)
		VALUES (CONCAT(CHAR(13), CHAR(10), ''## Views'')) ,(CONCAT(CHAR(13), CHAR(10), ''<details><summary>Click to expand</summary>'', CHAR(13), CHAR(10)));
		' +

		+ N'INSERT INTO #markdown (value)
		SELECT CONCAT(''* ['', OBJECT_SCHEMA_NAME(object_id), ''.'', OBJECT_NAME(object_id), ''](#'', REPLACE(LOWER(OBJECT_SCHEMA_NAME(object_id)), '' '', ''-''), REPLACE(LOWER(OBJECT_NAME(object_id)), '' '', ''-''), '')'')
		FROM [sys].[views]
		WHERE [is_ms_shipped] = 0
		ORDER BY OBJECT_SCHEMA_NAME([object_id]), [name] ASC;' +

		--Object details
		+ N'DECLARE obj_cursor CURSOR
		LOCAL STATIC READ_ONLY FORWARD_ONLY
		FOR
		SELECT [object_id]
		FROM [sys].[views]
		WHERE [is_ms_shipped] = 0
		ORDER BY OBJECT_SCHEMA_NAME([object_id]), [name] ASC;

		OPEN obj_cursor
		FETCH NEXT FROM obj_cursor INTO @ObjectId
		WHILE @@FETCH_STATUS = 0
		BEGIN

			INSERT INTO #markdown
			SELECT CONCAT(CHAR(13), CHAR(10), ''### '', OBJECT_SCHEMA_NAME(@ObjectId), ''.'', OBJECT_NAME(@ObjectId));' +

			--Main Extended Property (@ExtendedProperty)
			+ N'
			IF EXISTS (SELECT * FROM [sys].[views] AS [v]
						INNER JOIN [sys].[extended_properties] AS [ep] ON [v].[object_id] = [ep].[major_id]
						WHERE [v].[object_id] = @ObjectId
							AND [ep].[minor_id] = 0
							AND [ep].[name] = @ExtendedPropertyName)
			BEGIN;
				INSERT INTO #markdown (value)
				VALUES (CONCAT(CHAR(13), CHAR(10), ''| '', @ExtendedPropertyName COLLATE DATABASE_DEFAULT, '' |''))
				,(''| --- |'');

				INSERT INTO #markdown (value)
				SELECT CONCAT(''| '', REPLACE(REPLACE(REPLACE(REPLACE(CAST([ep].[value] AS NVARCHAR(4000)), ''|'', @PipeHTMLCode COLLATE DATABASE_DEFAULT), CHAR(13) + CHAR(10), @BreakHTMLCode COLLATE DATABASE_DEFAULT), ''`'', @TickHTMLCode COLLATE DATABASE_DEFAULT), '']'', @RightBracketHTMLCode COLLATE DATABASE_DEFAULT), '' |'')
				FROM [sys].[views] AS [v]
					INNER JOIN [sys].[extended_properties] AS [ep] ON [v].[object_id] = [ep].[major_id]
				WHERE [v].[object_id] = @ObjectId
					AND [ep].[minor_id] = 0
					AND [ep].[name] = @ExtendedPropertyName;
			END;';

			--All Extended Properties (non-@ExtendedProperty)
			IF @AllExtendedProperties = 1
				BEGIN
					SET @Sql = @Sql + N'
					IF EXISTS (SELECT * FROM [sys].[views] AS [v]
						INNER JOIN [sys].[extended_properties] AS [ep] ON [v].[object_id] = [ep].[major_id]
						WHERE [v].[object_id] = @ObjectId
							AND [ep].[minor_id] = 0
							AND [ep].[name] <> @ExtendedPropertyName)
					BEGIN;
						INSERT INTO #markdown (value)
						VALUES (CONCAT(CHAR(13), CHAR(10), ''#### '', ''Extended Properties''))
						,(CONCAT(CHAR(13), CHAR(10), ''| Name | Value |''))
						,(''| --- | --- |'');

						INSERT INTO #markdown (value)
						SELECT CONCAT(''| '', [ep].[name], '' | '', REPLACE(REPLACE(REPLACE(REPLACE(CAST([ep].[value] AS NVARCHAR(4000)), ''|'', @PipeHTMLCode COLLATE DATABASE_DEFAULT), CHAR(13) + CHAR(10), @BreakHTMLCode COLLATE DATABASE_DEFAULT), ''`'', @TickHTMLCode COLLATE DATABASE_DEFAULT), '']'', @RightBracketHTMLCode COLLATE DATABASE_DEFAULT), '' |'')
						FROM [sys].[views] AS [v]
							INNER JOIN [sys].[extended_properties] AS [ep] ON [v].[object_id] = [ep].[major_id]
						WHERE [v].[object_id] = @ObjectId
							AND [ep].[minor_id] = 0
							AND [ep].[name] <> @ExtendedPropertyName
						ORDER BY [ep].[name] ASC;
					END;';
				END

			--Projected columns
			SET @Sql = @Sql + N'
			INSERT INTO #markdown (value)
			VALUES (CONCAT(CHAR(13), CHAR(10), ''#### '', ''Columns''))
				,(CONCAT(CHAR(13), CHAR(10), ''| Column | Type | Null | '', @ExtendedPropertyName COLLATE DATABASE_DEFAULT, '' |''))
				,(''| --- | ---| --- | --- |'');

			INSERT INTO #markdown (value)
			SELECT CONCAT(''| '', [c].[name]
					,'' | ''
					,CONCAT(UPPER(TYPE_NAME([user_type_id]))
					,CASE
						WHEN TYPE_NAME([user_type_id]) IN (N''decimal'',N''numeric'')
						THEN CONCAT(N''('',CAST(precision AS varchar(5)), N'','',CAST(scale AS varchar(5)), N'')'')
						WHEN TYPE_NAME([user_type_id]) IN (''varchar'', ''char'', ''varbinary'')
						THEN CASE
								WHEN [max_length] = -1
								THEN N''(MAX)''
								ELSE QUOTENAME(CAST([max_length] AS VARCHAR(10)), ''('')
							END
						WHEN TYPE_NAME([user_type_id]) IN (N''time'',N''datetime2'',N''datetimeoffset'')
						THEN QUOTENAME(CAST(scale AS varchar(5)), ''('')
						WHEN TYPE_NAME([user_type_id]) in (N''float'')
						THEN CASE
								WHEN [c].precision = 53
								THEN N''''
								ELSE CONCAT(N''('',CAST([c].precision AS varchar(5)),N'')'')
							END
						WHEN TYPE_NAME([c].user_type_id) IN (N''int'',N''bigint'',N''smallint'',N''tinyint'',N''money'',N''smallmoney'',
							N''real'',N''datetime'',N''smalldatetime'',N''bit'',N''image'',N''text'',N''uniqueidentifier'',
							N''date'',N''ntext'',N''sql_variant'',N''hierarchyid'',''geography'',N''timestamp'',N''xml'')
						THEN N''''
						WHEN TYPE_NAME([user_type_id]) IN (N''nvarchar'',N''nchar'', N''sysname'')
						THEN CASE
								WHEN [max_length] = -1
								THEN N''(MAX)''
								ELSE QUOTENAME(CAST([max_length]/2 AS VARCHAR(10)), ''('')
							END
						ELSE QUOTENAME(CAST([max_length] AS VARCHAR(10)), ''('')
					END)
					,'' | ''
					,CASE [c].[is_nullable]
						WHEN 1
						THEN @Yes
						ELSE @No
						END
					,'' | ''
					,REPLACE(REPLACE(REPLACE(REPLACE(CAST([ep].[value] AS NVARCHAR(4000)), ''|'', @PipeHTMLCode COLLATE DATABASE_DEFAULT), CHAR(13) + CHAR(10), @BreakHTMLCode COLLATE DATABASE_DEFAULT), ''`'', @TickHTMLCode COLLATE DATABASE_DEFAULT), '']'', @RightBracketHTMLCode COLLATE DATABASE_DEFAULT)
					,'' |'')
			FROM [sys].[views] AS [o]
				INNER JOIN [sys].[columns] AS [c] ON [o].[object_id] = [c].[object_id]
				LEFT JOIN [sys].[extended_properties] AS [ep] ON [o].[object_id] = [ep].[major_id]
					AND [ep].[minor_id] = [c].[column_id]
					AND [ep].[name] = @ExtendedPropertyName
			WHERE [o].[is_ms_shipped] = 0	-- User objects only
				AND [o].[type] = ''V''		-- VIEW
				AND [o].[object_id] = @ObjectId
			ORDER BY SCHEMA_NAME([o].[schema_id]), [o].[type_desc], OBJECT_NAME([ep].major_id);';

			--View Column Extended Properties
			IF @AllExtendedProperties = 1
				BEGIN
					SET @Sql = @Sql + N'
					IF EXISTS (SELECT * FROM [sys].[views] AS [o]
											INNER JOIN [sys].[columns] AS [c] ON [o].[object_id] = [c].[object_id]
											INNER JOIN [sys].[extended_properties] AS [ep] ON [o].[object_id] = [ep].[major_id]
												AND [ep].[minor_id] = [c].[column_id]
												AND [ep].[name] <> @ExtendedPropertyName
										WHERE [o].[is_ms_shipped] = 0	-- User objects only
											AND [o].[type] = ''V''		-- VIEW
											AND [o].[object_id] = @ObjectId)
					BEGIN
						INSERT INTO #markdown (value)
						VALUES (CONCAT(CHAR(13), CHAR(10), ''##### '', ''Column Extended Properties''))
						,(CONCAT(CHAR(13), CHAR(10), ''Column | Name | Value |''))
						,(''| --- | --- | --- |'');

						INSERT INTO #markdown (value)
						SELECT CONCAT(''| '', [c].[name], '' | '', [ep].[name], '' | '', REPLACE(REPLACE(REPLACE(REPLACE(CAST([ep].[value] AS NVARCHAR(4000)), ''|'', @PipeHTMLCode COLLATE DATABASE_DEFAULT), CHAR(13) + CHAR(10), @BreakHTMLCode COLLATE DATABASE_DEFAULT), ''`'', @TickHTMLCode COLLATE DATABASE_DEFAULT), '']'', @RightBracketHTMLCode COLLATE DATABASE_DEFAULT) COLLATE DATABASE_DEFAULT, '' |'')
						FROM [sys].[views] AS [o]
							INNER JOIN [sys].[columns] AS [c] ON [o].[object_id] = [c].[object_id]
							INNER JOIN [sys].[extended_properties] AS [ep] ON [o].[object_id] = [ep].[major_id]
								AND [ep].[minor_id] = [c].[column_id]
								AND [ep].[name] <> @ExtendedPropertyName
						WHERE [o].[is_ms_shipped] = 0	-- User objects only
							AND [o].[type] = ''V''		-- VIEW
							AND [o].[object_id] = @ObjectId
						ORDER BY [c].[name], [ep].[name] ASC;
					END;';
				END

			--Object definition
			SET @Sql = @Sql + N'
			INSERT INTO #markdown (value)
			VALUES(CONCAT(CHAR(13), CHAR(10), ''#### Definition''))
				,(CONCAT(CHAR(13), CHAR(10), ''<details><summary>Click to expand</summary>''))
				,(CONCAT(CHAR(13), CHAR(10), ''```sql'', CHAR(13), CHAR(10), OBJECT_DEFINITION(@ObjectId)))
				,(''```'')
				,(CONCAT(CHAR(13), CHAR(10), ''</details>''));
				' +

			--Indexes
			+ N'IF EXISTS (SELECT 1 FROM [sys].[indexes] WHERE [object_id] = @ObjectId)
			BEGIN
				INSERT INTO #markdown
				SELECT CONCAT(CHAR(13), CHAR(10), ''#### '', ''Indexes'')
				DECLARE [index_cursor] CURSOR
				LOCAL STATIC READ_ONLY FORWARD_ONLY
				FOR
				SELECT [ind].[index_id]
				FROM [sys].[indexes] AS [ind]
				WHERE [ind].[object_id] = @ObjectId
					AND [ind].[type] > 0 -- Not heap
				ORDER BY [ind].[is_primary_key] DESC, [ind].[is_unique_constraint] DESC, [ind].[name] DESC

				INSERT INTO #markdown (value)
					VALUES (CONCAT(CHAR(13), CHAR(10), ''| Name | Type | Key Columns | Include Columns | '', @ExtendedPropertyName COLLATE DATABASE_DEFAULT, '' |''))
					,(''| --- | --- | --- | --- | --- |'');

				OPEN [index_cursor]
				FETCH NEXT FROM [index_cursor] INTO @IndexObjectId
				WHILE @@FETCH_STATUS = 0
				BEGIN
				' +
					-- Get key columns as a csv list
					+ N'SELECT @KeyColumns = STUFF((
							SELECT CONCAT('', '', QUOTENAME([col].[name]))
							FROM [sys].[indexes] AS [ind]
								INNER JOIN [sys].[index_columns] AS [ic] ON [ind].[object_id] = [ic].[object_id]
									AND [ic].[index_id] = [ind].[index_id]
								INNER JOIN [sys].[columns] AS [col] ON [ic].[object_id] = [col].[object_id]
									AND [ic].[column_id] = [col].[column_id]
							WHERE [ind].[object_id] = @ObjectId
								AND [ind].[index_id] = @IndexObjectId
								AND [ic].[is_included_column] = 0
							FOR XML PATH('''')
						), 1, 2, ''''); ' +

					-- Get included columns as a csv list
					+ N'SELECT @IncludeColumns = STUFF((
							SELECT CONCAT('', '', QUOTENAME([col].[name]))
							FROM [sys].[indexes] AS [ind]
								INNER JOIN [sys].[index_columns] AS [ic] ON [ind].[object_id] = [ic].[object_id]
									AND [ic].[index_id] = [ind].[index_id]
								INNER JOIN [sys].[columns] AS [col] ON [ic].[object_id] = [col].[object_id]
									AND [ic].[column_id] = [col].[column_id]
							WHERE [ind].[object_id] = @ObjectId
								AND [ind].[index_id] = @IndexObjectId
								AND [ic].[is_included_column] = 1
							FOR XML PATH('''')
						), 1, 2, '''');

					INSERT INTO #markdown (value)
					SELECT CONCAT(''| ''
						,CASE
							WHEN [ind].[is_primary_key] = 1
                        	THEN CONCAT(@PK, ''**'',[ind].[name],''**'')
							ELSE [ind].[name]
						END
						, '' | ''
						, LOWER([ind].[type_desc]) COLLATE DATABASE_DEFAULT
						, '' | ''
						, @KeyColumns COLLATE DATABASE_DEFAULT
						, '' | ''
						, @IncludeColumns COLLATE DATABASE_DEFAULT
						, '' | ''
						, REPLACE(REPLACE(REPLACE(REPLACE(CAST([ep].[value] AS NVARCHAR(4000)), ''|'', @PipeHTMLCode COLLATE DATABASE_DEFAULT), CHAR(13) + CHAR(10), @BreakHTMLCode COLLATE DATABASE_DEFAULT), ''`'', @TickHTMLCode COLLATE DATABASE_DEFAULT), '']'', @RightBracketHTMLCode COLLATE DATABASE_DEFAULT) COLLATE DATABASE_DEFAULT
						, '' |'')
					FROM [sys].[indexes] AS [ind]
						LEFT JOIN [sys].[extended_properties] AS [ep] ON [ind].[object_id] = [ep].[major_id]
							AND [ep].[minor_id] = [ind].[index_id]
							AND [ep].[class] = 7 -- Index
							AND [ep].[name] = @ExtendedPropertyName
					WHERE [ind].[object_id] = @ObjectId
						AND [ind].[index_id] = @IndexObjectId;

					FETCH NEXT FROM [index_cursor] INTO @IndexObjectId;
				END;

				CLOSE [index_cursor];
				DEALLOCATE [index_cursor];
			END;';

			--Index Extended Properties
			IF @AllExtendedProperties = 1
				BEGIN;
					SET @Sql = @Sql + N'
					IF EXISTS (SELECT * FROM [sys].[indexes] AS [ind]
											INNER JOIN [sys].[extended_properties] AS [ep] ON [ind].[object_id] = [ep].[major_id]
												AND [ep].[minor_id] = [ind].[index_id]
												AND [ep].[class] = 7 -- Index
										WHERE [ind].[object_id] = @ObjectId
										AND [ep].[name] <> @ExtendedPropertyName)
					BEGIN
						INSERT INTO #markdown (value)
						VALUES (CONCAT(CHAR(13), CHAR(10), ''##### '', ''Index Extended Properties''))
						,(CONCAT(CHAR(13), CHAR(10), ''Index | Name | Value |''))
						,(''| --- | --- | --- |'');

						INSERT INTO #markdown (value)
						SELECT CONCAT(''| '', [ind].[name], '' | '', [ep].[name], '' | '', REPLACE(REPLACE(REPLACE(REPLACE(CAST([ep].[value] AS NVARCHAR(4000)), ''|'', @PipeHTMLCode COLLATE DATABASE_DEFAULT), CHAR(13) + CHAR(10), @BreakHTMLCode COLLATE DATABASE_DEFAULT), ''`'', @TickHTMLCode COLLATE DATABASE_DEFAULT), '']'', @RightBracketHTMLCode COLLATE DATABASE_DEFAULT) COLLATE DATABASE_DEFAULT, '' |'')
						FROM [sys].[indexes] AS [ind]
							LEFT JOIN [sys].[extended_properties] AS [ep] ON [ind].[object_id] = [ep].[major_id]
								AND [ep].[minor_id] = [ind].[index_id]
								AND [ep].[class] = 7 -- Index
						WHERE [ind].[object_id] = @ObjectId
							AND [ep].[name] <> @ExtendedPropertyName
						ORDER BY [ind].[name], [ep].[name] ASC;
					END;';
				END;

			--Dependencies
			SET @Sql = @Sql + N'
			IF EXISTS (SELECT 1 FROM [sys].[dm_sql_referencing_entities] (CONCAT(OBJECT_SCHEMA_NAME(@ObjectId), ''.'', OBJECT_NAME(@ObjectId)), ''OBJECT''))
			BEGIN
				INSERT INTO #markdown (value)
				SELECT CONCAT(CHAR(13), CHAR(10), ''#### '', ''Referenced By'');

				INSERT INTO #markdown (value)
				VALUES (CONCAT(CHAR(13), CHAR(10), ''| Object | Type |''))
					,(''| --- | --- |'');

				INSERT INTO #markdown (value)
				SELECT CONCAT(''| ''
						, CONCAT(''['',QUOTENAME([ref].[referencing_schema_name]), ''.'', QUOTENAME([ref].[referencing_entity_name]),'']'',''(#'',LOWER([ref].[referencing_schema_name]), LOWER([ref].[referencing_entity_name]), '')'')
						,'' | ''
						, REPLACE(LOWER([o].[type_desc]), ''_'' COLLATE DATABASE_DEFAULT, '' '' COLLATE DATABASE_DEFAULT)
						, '' |'') COLLATE DATABASE_DEFAULT
				FROM [sys].[dm_sql_referencing_entities] (CONCAT(OBJECT_SCHEMA_NAME(@ObjectId), ''.'', OBJECT_NAME(@ObjectId)), ''OBJECT'') [ref]
				INNER JOIN [sys].[objects] [o] on [o].[object_id] = [ref].[referencing_id]
				WHERE [ref].[referencing_id] <> @ObjectId -- Exclude self-references
				ORDER BY 1;
			END;' +

			--Back to top
			+ N'INSERT INTO #markdown
			VALUES (CONCAT(CHAR(13), CHAR(10), ''[Back to top](#'', LOWER(@DatabaseName COLLATE DATABASE_DEFAULT), '')''));

			FETCH NEXT FROM obj_cursor INTO @ObjectId;

		END;
		CLOSE obj_cursor;
		DEALLOCATE obj_cursor;' +

		--End collapsible view section
		+ N'INSERT INTO #markdown
		VALUES (CONCAT(CHAR(13), CHAR(10), ''</details>''));
	END;'; --End markdown for views

	/**************************************
	Generate markdown for stored procedures
	**************************************/
	--Build table of contents
	SET @Sql = @Sql + N'
	IF EXISTS (SELECT 1 FROM [sys].[procedures] WHERE [is_ms_shipped] = 0)
	BEGIN;
		INSERT INTO #markdown
		VALUES (CONCAT(CHAR(13), CHAR(10), ''## Stored Procedures'')) ,(CONCAT(CHAR(13), CHAR(10), ''<details><summary>Click to expand</summary>'', CHAR(13), CHAR(10)));
		' +

		+ N'INSERT INTO #markdown
		SELECT CONCAT(''* ['', OBJECT_SCHEMA_NAME(object_id), ''.'', OBJECT_NAME(object_id), ''](#'', REPLACE(LOWER(OBJECT_SCHEMA_NAME(object_id)), '' '', ''-''), REPLACE(LOWER(OBJECT_NAME(object_id)), '' '', ''-''), '')'')
		FROM [sys].[procedures]
		WHERE [is_ms_shipped] = 0
		ORDER BY OBJECT_SCHEMA_NAME(object_id), [name] ASC;' +

		--Object details
		+ N'DECLARE obj_cursor CURSOR
		LOCAL STATIC READ_ONLY FORWARD_ONLY
		FOR
		SELECT [object_id]
		FROM [sys].[procedures]
		WHERE [is_ms_shipped] = 0
		ORDER BY OBJECT_SCHEMA_NAME([object_id]), [name] ASC;

		OPEN obj_cursor
		FETCH NEXT FROM obj_cursor INTO @ObjectId
		WHILE @@FETCH_STATUS = 0
		BEGIN

			INSERT INTO #markdown
			SELECT CONCAT(CHAR(13), CHAR(10), ''### '', OBJECT_SCHEMA_NAME(@ObjectId), ''.'', OBJECT_NAME(@ObjectId));' +

			--Main Extended Property (@ExtendedProperty)
			+ N'
			IF EXISTS (SELECT * FROM [sys].[procedures] AS [p]
											INNER JOIN [sys].[extended_properties] AS [ep] ON [p].[object_id] = [ep].[major_id]
										WHERE [p].[object_id] = @ObjectId
											AND [ep].[minor_id] = 0
											AND [ep].[name] = @ExtendedPropertyName)
			BEGIN;
				INSERT INTO #markdown (value)
				VALUES (CONCAT(CHAR(13), CHAR(10), ''| '', @ExtendedPropertyName COLLATE DATABASE_DEFAULT, '' |''))
				,(''| --- |'');

				INSERT INTO #markdown (value)
				SELECT CONCAT(''| '', REPLACE(REPLACE(REPLACE(REPLACE(CAST([ep].[value] AS NVARCHAR(4000)), ''|'', @PipeHTMLCode COLLATE DATABASE_DEFAULT), CHAR(13) + CHAR(10), @BreakHTMLCode COLLATE DATABASE_DEFAULT), ''`'', @TickHTMLCode COLLATE DATABASE_DEFAULT), '']'', @RightBracketHTMLCode COLLATE DATABASE_DEFAULT), '' |'')
				FROM [sys].[procedures] AS [p]
					INNER JOIN [sys].[extended_properties] AS [ep] ON [p].[object_id] = [ep].[major_id]
				WHERE [p].[object_id] = @ObjectId
					AND [ep].[minor_id] = 0
					AND [ep].[name] = @ExtendedPropertyName;
			END;';

			--All Extended Properties (non-@ExtendedProperty)
			IF @AllExtendedProperties = 1
				BEGIN
					SET @Sql = @Sql + N'
					IF EXISTS (SELECT * FROM [sys].[procedures] AS [p]
											INNER JOIN [sys].[extended_properties] AS [ep] ON [p].[object_id] = [ep].[major_id]
										WHERE [p].[object_id] = @ObjectId
											AND [ep].[minor_id] = 0
											AND [ep].[name] NOT IN (
											SELECT [param].[name] FROM [sys].[procedures] AS [proc]
													INNER JOIN [sys].[parameters] AS [param] ON [param].[object_id] = [proc].[object_id]
												WHERE [proc].[object_id] = @ObjectId)
											AND [ep].[name] <> @ExtendedPropertyName)
					BEGIN;
						INSERT INTO #markdown (value)
						VALUES (CONCAT(CHAR(13), CHAR(10), ''#### '', ''Extended Properties''))
						,(CONCAT(CHAR(13), CHAR(10), ''| Name | Value |''))
						,(''| --- | --- |'');
						INSERT INTO #markdown (value)
						SELECT CONCAT(''| '', [ep].[name], '' | '', REPLACE(REPLACE(REPLACE(REPLACE(CAST([ep].[value] AS NVARCHAR(4000)), ''|'', @PipeHTMLCode COLLATE DATABASE_DEFAULT), CHAR(13) + CHAR(10), @BreakHTMLCode COLLATE DATABASE_DEFAULT), ''`'', @TickHTMLCode COLLATE DATABASE_DEFAULT), '']'', @RightBracketHTMLCode COLLATE DATABASE_DEFAULT), '' |'')
						FROM [sys].[procedures] AS [p]
							INNER JOIN [sys].[extended_properties] AS [ep] ON [p].[object_id] = [ep].[major_id]
						WHERE [p].[object_id] = @ObjectId
							AND [ep].[minor_id] = 0
							AND [ep].[name] <> @ExtendedPropertyName
							AND [ep].[name] NOT IN (
									SELECT [param].[name] FROM [sys].[procedures] AS [proc]
											INNER JOIN [sys].[parameters] AS [param] ON [param].[object_id] = [proc].[object_id]
										WHERE [proc].[object_id] = @ObjectId)
						ORDER BY [ep].[name] ASC;
					END;';
				END

			--Check for parameters
			SET @Sql = @Sql + N'
			IF EXISTS (SELECT * FROM [sys].[parameters] AS [param] WHERE [param].[object_id] = @ObjectId)
			BEGIN
				INSERT INTO #markdown (value)
				VALUES (CONCAT(CHAR(13), CHAR(10), ''#### '', ''Parameters''))
					,(CONCAT(CHAR(13), CHAR(10), ''| Parameter | Type | Output | Description |''))
					,(''| --- | --- | --- | --- |'');

				INSERT INTO #markdown (value)
				SELECT CONCAT(''| '', CASE WHEN LEN([param].[name]) = 0 THEN ''*Output*'' ELSE [param].[name] END
						,'' | ''
						,CONCAT(UPPER(TYPE_NAME([user_type_id]))
						,CASE
							WHEN TYPE_NAME([user_type_id]) IN (N''decimal'',N''numeric'')
							THEN CONCAT(N''('',CAST(precision AS varchar(5)), N'','',CAST(scale AS varchar(5)), N'')'')
							WHEN TYPE_NAME([user_type_id]) IN (''varchar'', ''char'', ''varbinary'')
							THEN CASE
									WHEN [max_length] = -1
									THEN N''(MAX)''
									ELSE QUOTENAME(CAST([max_length] AS VARCHAR(10)), ''('')
								END
							WHEN TYPE_NAME([user_type_id]) IN (N''time'',N''datetime2'',N''datetimeoffset'')
							THEN QUOTENAME(CAST(scale AS varchar(5)), ''('')
							WHEN TYPE_NAME([user_type_id]) in (N''float'')
							THEN CASE
									WHEN [param].precision = 53
									THEN N''''
									ELSE CONCAT(N''('',CAST([param].precision AS varchar(5)),N'')'')
								END
							WHEN TYPE_NAME([param].user_type_id) IN (N''int'',N''bigint'',N''smallint'',N''tinyint'',N''money'',N''smallmoney'',
								N''real'',N''datetime'',N''smalldatetime'',N''bit'',N''image'',N''text'',N''uniqueidentifier'',
								N''date'',N''ntext'',N''sql_variant'',N''hierarchyid'',''geography'',N''timestamp'',N''xml'') OR [is_readonly] = 1
							THEN N''''
							WHEN TYPE_NAME([user_type_id]) IN (N''nvarchar'',N''nchar'', N''sysname'')
							THEN CASE
									WHEN [max_length] = -1
									THEN N''(MAX)''
									ELSE QUOTENAME(CAST([max_length]/2 AS VARCHAR(10)), ''('')
								END
							ELSE QUOTENAME(CAST([max_length] AS VARCHAR(10)), ''('')
						END)
						,'' | ''
						,CASE [is_output]
							WHEN 1
							THEN @Yes
							ELSE @No
						END
						,'' | ''
						,REPLACE(REPLACE(REPLACE(REPLACE(CAST([ep].[value] AS NVARCHAR(4000)), ''|'', @PipeHTMLCode COLLATE DATABASE_DEFAULT), CHAR(13) + CHAR(10), @BreakHTMLCode COLLATE DATABASE_DEFAULT), ''`'', @TickHTMLCode COLLATE DATABASE_DEFAULT), '']'', @RightBracketHTMLCode COLLATE DATABASE_DEFAULT)
						, '' |'')
				FROM [sys].[procedures] AS [proc]
					INNER JOIN [sys].[parameters] AS [param] ON [param].[object_id] = [proc].[object_id]
					LEFT JOIN [sys].[extended_properties] AS [ep] ON [proc].[object_id] = [ep].[major_id]
						AND [ep].[name] = [param].[name]
				WHERE [proc].[object_id] = @ObjectId
				ORDER BY [param].[parameter_id] ASC;
			END

			INSERT INTO #markdown (value)
			VALUES(CONCAT(CHAR(13), CHAR(10), ''#### Definition''))
				,(CONCAT(CHAR(13), CHAR(10), ''<details><summary>Click to expand</summary>''));' +

			--Object definition
			+ N'
			IF (@LimitStoredProcLength = 1 AND LEN(OBJECT_DEFINITION(@ObjectId)) > 8000)
				BEGIN;
					INSERT INTO #markdown (value)
					VALUES (CONCAT(CHAR(13), CHAR(10), ''```sql'',
					CHAR(13), CHAR(10), CAST(OBJECT_DEFINITION(@ObjectId) AS VARCHAR(8000))))
					,(''/************************************************************************************************/'')
					,(''/* sp_doc: Max 8000 characters reached. Set @LimitStoredProcLength = 0 to show full definition. */'')
					,(''/************************************************************************************************/'');
				END;
			ELSE
				BEGIN;
					INSERT INTO #markdown (value)
					VALUES (CONCAT(CHAR(13), CHAR(10), ''```sql'',
					CHAR(13), CHAR(10), OBJECT_DEFINITION(@ObjectId)));
				END;

			INSERT INTO #markdown (value)
			VALUES (''```'')
				,(CONCAT(CHAR(13), CHAR(10), ''</details>''));' +

			--Dependencies
			+ N'IF EXISTS (SELECT 1 FROM [sys].[dm_sql_referencing_entities] (CONCAT(OBJECT_SCHEMA_NAME(@ObjectId), ''.'', OBJECT_NAME(@ObjectId)), ''OBJECT''))
			BEGIN
				INSERT INTO #markdown (value)
				SELECT CONCAT(CHAR(13), CHAR(10), ''#### '', ''Referenced By'');

				INSERT INTO #markdown (value)
				VALUES (CONCAT(CHAR(13), CHAR(10), ''| Object | Type |''))
					,(''| --- | --- |'');

				INSERT INTO #markdown (value)
				SELECT CONCAT(''| ''
						, CONCAT(''['',QUOTENAME([ref].[referencing_schema_name]), ''.'', QUOTENAME([ref].[referencing_entity_name]),'']'',''(#'',LOWER([ref].[referencing_schema_name]), LOWER([ref].[referencing_entity_name]), '')'')
						,'' | ''
						, REPLACE(LOWER([o].[type_desc]), ''_'' COLLATE DATABASE_DEFAULT, '' '' COLLATE DATABASE_DEFAULT)
						, '' |'') COLLATE DATABASE_DEFAULT
				FROM [sys].[dm_sql_referencing_entities] (CONCAT(OBJECT_SCHEMA_NAME(@ObjectId), ''.'', OBJECT_NAME(@ObjectId)), ''OBJECT'') [ref]
					INNER JOIN [sys].[objects] [o] on [o].[object_id] = [ref].[referencing_id]
				WHERE [ref].[referencing_id] <> @ObjectId -- Exclude self-references
				ORDER BY 1;
			END;' +

			--Back to top
			+ N'INSERT INTO #markdown
			VALUES (CONCAT(CHAR(13), CHAR(10), ''[Back to top](#'', LOWER(@DatabaseName COLLATE DATABASE_DEFAULT), '')''));

			FETCH NEXT FROM obj_cursor INTO @ObjectId

		END;
		CLOSE obj_cursor;
		DEALLOCATE obj_cursor;' +

		--End collapsible stored procedure section
		+ N'INSERT INTO #markdown
		VALUES (CONCAT(CHAR(13), CHAR(10), ''</details>''));
	END;'; --End markdown for stored procedures

	/*************************************
	Generate markdown for scalar functions
	*************************************/
	--Build table of contents
	SET @Sql = @Sql + N'
	IF EXISTS (SELECT 1 FROM [sys].[objects] WHERE [is_ms_shipped] = 0 AND [type] = ''FN'')
	BEGIN;
		INSERT INTO #markdown (value)
		VALUES (CONCAT(CHAR(13), CHAR(10), ''## Scalar Functions'')) ,(CONCAT(CHAR(13), CHAR(10), ''<details><summary>Click to expand</summary>'', CHAR(13), CHAR(10)));' +

		+ N'INSERT INTO #markdown
		SELECT CONCAT(''* ['', OBJECT_SCHEMA_NAME(object_id), ''.'', OBJECT_NAME(object_id), ''](#'', REPLACE(LOWER(OBJECT_SCHEMA_NAME(object_id)), '' '', ''-''), REPLACE(LOWER(OBJECT_NAME(object_id)), '' '', ''-''), '')'')
		FROM [sys].[objects]
		WHERE [is_ms_shipped] = 0
			AND [type] = ''FN'' --SQL_SCALAR_FUNCTION
		ORDER BY OBJECT_SCHEMA_NAME([object_id]), [name] ASC;' +

		--Object details
		+ N'DECLARE obj_cursor CURSOR
		LOCAL STATIC READ_ONLY FORWARD_ONLY
		FOR
		SELECT [object_id]
		FROM [sys].[objects]
		WHERE [is_ms_shipped] = 0
			AND [type] = ''FN'' --SQL_SCALAR_FUNCTION
		ORDER BY OBJECT_SCHEMA_NAME([object_id]), [name] ASC;

		OPEN obj_cursor
		FETCH NEXT FROM obj_cursor INTO @ObjectId
		WHILE @@FETCH_STATUS = 0
		BEGIN

			INSERT INTO #markdown
			SELECT CONCAT(CHAR(13), CHAR(10), ''### '', OBJECT_SCHEMA_NAME(@ObjectId), ''.'', OBJECT_NAME(@ObjectId));' +

			--Main Extended Property (@ExtendedProperty)
			+ N'
			IF EXISTS (SELECT * FROM [sys].[objects] AS [o]
										INNER JOIN [sys].[extended_properties] AS [ep] ON [o].[object_id] = [ep].[major_id]
										WHERE [o].[object_id] = @ObjectId
											AND [ep].[minor_id] = 0
											AND [ep].[name] = @ExtendedPropertyName)

			BEGIN;
				INSERT INTO #markdown (value)
				VALUES (CONCAT(CHAR(13), CHAR(10), ''| '', @ExtendedPropertyName COLLATE DATABASE_DEFAULT, '' |''))
				,(''| --- |'');

				INSERT INTO #markdown
				SELECT CONCAT('' |'', REPLACE(REPLACE(REPLACE(REPLACE(CAST([ep].[value] AS NVARCHAR(4000)), ''|'', @PipeHTMLCode COLLATE DATABASE_DEFAULT), CHAR(13) + CHAR(10), @BreakHTMLCode COLLATE DATABASE_DEFAULT), ''`'', @TickHTMLCode COLLATE DATABASE_DEFAULT), '']'', @RightBracketHTMLCode COLLATE DATABASE_DEFAULT), '' |'')
				FROM [sys].[objects] AS [o]
					INNER JOIN [sys].[extended_properties] AS [ep] ON [o].[object_id] = [ep].[major_id]
				WHERE [o].[object_id] = @ObjectId
					AND [ep].[minor_id] = 0
					AND [ep].[name] = @ExtendedPropertyName;
			END;';

			--All Extended Properties (non-@ExtendedProperty)
			IF @AllExtendedProperties = 1
				BEGIN
					SET @Sql = @Sql + N'
					IF EXISTS (SELECT * FROM [sys].[objects] AS [o]
										INNER JOIN [sys].[extended_properties] AS [ep] ON [o].[object_id] = [ep].[major_id]
										WHERE [o].[object_id] = @ObjectId
											AND [ep].[minor_id] = 0
											AND [ep].[name] NOT IN (
												SELECT [param].[name] FROM [sys].[objects] AS [o]
													INNER JOIN [sys].[parameters] AS [param] ON [param].[object_id] = [o].[object_id]
												WHERE [o].[object_id] = @ObjectId)
											AND [ep].[name] <> @ExtendedPropertyName)

					BEGIN;
						INSERT INTO #markdown (value)
						VALUES (CONCAT(CHAR(13), CHAR(10), ''#### '', ''Extended Properties''))
						,(CONCAT(CHAR(13), CHAR(10), ''| Name | Value |''))
						,(''| --- | --- |'');

						INSERT INTO #markdown
						SELECT CONCAT(''| '', [ep].[name], '' | '', REPLACE(REPLACE(REPLACE(REPLACE(CAST([ep].[value] AS NVARCHAR(4000)), ''|'', @PipeHTMLCode COLLATE DATABASE_DEFAULT), CHAR(13) + CHAR(10), @BreakHTMLCode COLLATE DATABASE_DEFAULT), ''`'', @TickHTMLCode COLLATE DATABASE_DEFAULT), '']'', @RightBracketHTMLCode COLLATE DATABASE_DEFAULT), '' |'')
						FROM [sys].[objects] AS [o]
							INNER JOIN [sys].[extended_properties] AS [ep] ON [o].[object_id] = [ep].[major_id]
						WHERE [o].[object_id] = @ObjectId
							AND [ep].[minor_id] = 0
							AND [ep].[name] <> @ExtendedPropertyName
							AND [ep].[name] NOT IN (
									SELECT [param].[name] FROM [sys].[objects] AS [o]
										INNER JOIN [sys].[parameters] AS [param] ON [param].[object_id] = [o].[object_id]
									WHERE [o].[object_id] = @ObjectId)
						ORDER BY [ep].[name] ASC;
					END;';
				END

			--Check for parameters
			SET @Sql = @Sql + N'
			IF EXISTS (SELECT * FROM [sys].[parameters] AS [param] WHERE [param].[object_id] = @ObjectId)
			BEGIN
				INSERT INTO #markdown (value)
				VALUES (CONCAT(CHAR(13), CHAR(10), ''#### '', ''Parameters''))
					,(CONCAT(CHAR(13), CHAR(10), ''| Parameter | Type | Output | Description |''))
					,(''| --- | --- | --- | --- |'');

				INSERT INTO #markdown
				select CONCAT(''| '', CASE WHEN LEN([param].[name]) = 0 THEN ''*Output*'' ELSE [param].[name] END
						,'' | ''
						,CONCAT(UPPER(TYPE_NAME([user_type_id]))
						,CASE
							WHEN TYPE_NAME([user_type_id]) IN (N''decimal'',N''numeric'')
							THEN CONCAT(N''('',CAST(precision AS varchar(5)), N'','',CAST(scale AS varchar(5)), N'')'')
							WHEN TYPE_NAME([user_type_id]) IN (''varchar'', ''char'', ''varbinary'')
							THEN CASE
									WHEN [max_length] = -1
									THEN N''(MAX)''
									ELSE QUOTENAME(CAST([max_length] AS VARCHAR(10)), ''('')
								END
							WHEN TYPE_NAME([user_type_id]) IN (N''time'',N''datetime2'',N''datetimeoffset'')
							THEN QUOTENAME(CAST(scale AS varchar(5)), ''('')
							WHEN TYPE_NAME([user_type_id]) in (N''float'')
							THEN CASE
									WHEN [param].precision = 53
									THEN N''''
									ELSE CONCAT(N''('',CAST([param].precision AS varchar(5)),N'')'')
								END
							WHEN TYPE_NAME([param].user_type_id) IN (N''int'',N''bigint'',N''smallint'',N''tinyint'',N''money'',N''smallmoney'',
								N''real'',N''datetime'',N''smalldatetime'',N''bit'',N''image'',N''text'',N''uniqueidentifier'',
								N''date'',N''ntext'',N''sql_variant'',N''hierarchyid'',''geography'',N''timestamp'',N''xml'') OR [is_readonly] = 1
							THEN N''''
							WHEN TYPE_NAME([user_type_id]) IN (N''nvarchar'',N''nchar'', N''sysname'')
							THEN CASE
									WHEN [max_length] = -1
									THEN N''(MAX)''
									ELSE QUOTENAME(CAST([max_length]/2 AS VARCHAR(10)), ''('')
								END
							ELSE QUOTENAME(CAST([max_length] AS VARCHAR(10)), ''('')
						END)
						,'' | ''
						,CASE [is_output]
							WHEN 1
							THEN @Yes
							ELSE @No
							END
						,'' | ''
						,REPLACE(REPLACE(REPLACE(REPLACE(CAST([ep].[value] AS NVARCHAR(4000)), ''|'', @PipeHTMLCode COLLATE DATABASE_DEFAULT), CHAR(13) + CHAR(10), @BreakHTMLCode COLLATE DATABASE_DEFAULT), ''`'', @TickHTMLCode COLLATE DATABASE_DEFAULT), '']'', @RightBracketHTMLCode COLLATE DATABASE_DEFAULT)
						, '' |'')
				FROM [sys].[objects] AS [o]
					INNER JOIN [sys].[parameters] AS [param] ON [param].[object_id] = [o].[object_id]
					LEFT JOIN [sys].[extended_properties] AS [ep] ON [o].[object_id] = [ep].[major_id]
						AND [ep].[name] = [param].[name]
				WHERE [o].[object_id] = @ObjectId
				ORDER BY [param].[parameter_id] ASC;
			END;' +

			--Object definition
			+ N'INSERT INTO #markdown (value)
			VALUES(CONCAT(CHAR(13), CHAR(10), ''#### Definition''))
				,(CONCAT(CHAR(13), CHAR(10), ''<details><summary>Click to expand</summary>''))
				,(CONCAT(CHAR(13), CHAR(10), ''```sql'', CHAR(13), CHAR(10), OBJECT_DEFINITION(@ObjectId)))
				,(''```'')
				,(CONCAT(CHAR(13), CHAR(10), ''</details>''))' +

			--Dependencies
			+ N'IF EXISTS (SELECT 1 FROM [sys].[dm_sql_referencing_entities] (CONCAT(OBJECT_SCHEMA_NAME(@ObjectId), ''.'', OBJECT_NAME(@ObjectId)), ''OBJECT''))
			BEGIN
				INSERT INTO #markdown (value)
				SELECT CONCAT(CHAR(13), CHAR(10), ''#### '', ''Referenced By'');

				INSERT INTO #markdown (value)
				VALUES (CONCAT(CHAR(13), CHAR(10), ''| Object | Type |''))
					,(''| --- | --- |'');

				INSERT INTO #markdown (value)
				SELECT CONCAT(''| ''
						, CONCAT(''['',QUOTENAME([ref].[referencing_schema_name]), ''.'', QUOTENAME([ref].[referencing_entity_name]),'']'',''(#'',LOWER([ref].[referencing_schema_name]), LOWER([ref].[referencing_entity_name]), '')'')
						,'' | ''
						, REPLACE(LOWER([o].[type_desc]), ''_'' COLLATE DATABASE_DEFAULT, '' '' COLLATE DATABASE_DEFAULT)
						, '' |'') COLLATE DATABASE_DEFAULT
				FROM [sys].[dm_sql_referencing_entities] (CONCAT(OBJECT_SCHEMA_NAME(@ObjectId), ''.'', OBJECT_NAME(@ObjectId)), ''OBJECT'') [ref]
					INNER JOIN [sys].[objects] [o] on [o].[object_id] = [ref].[referencing_id]
				WHERE [ref].[referencing_id] <> @ObjectId -- Exclude self-references
				ORDER BY 1;
			END;' +

			--Back to top
			+ N'INSERT INTO #markdown
			VALUES (CONCAT(CHAR(13), CHAR(10), ''[Back to top](#'', LOWER(@DatabaseName COLLATE DATABASE_DEFAULT), '')''));

			FETCH NEXT FROM obj_cursor INTO @ObjectId;

		END;
		CLOSE obj_cursor;
		DEALLOCATE obj_cursor;' +

		--End collapsible scalar functions section
		+ N'INSERT INTO #markdown
		VALUES (CONCAT(CHAR(13), CHAR(10), ''</details>''));
	END;'; --End markdown for scalar functions

	/************************************
	Generate markdown for table functions
	************************************/
	--Build table of contents
	SET @Sql = @Sql + N'
	IF EXISTS (SELECT 1 FROM [sys].[objects] WHERE [is_ms_shipped] = 0 AND [type] = ''IF'')
	BEGIN;
		INSERT INTO #markdown
		VALUES (CONCAT(CHAR(13), CHAR(10), ''## Table Functions'')) ,(CONCAT(CHAR(13), CHAR(10), ''<details><summary>Click to expand</summary>'', CHAR(13), CHAR(10)));
		' +

		+ N'INSERT INTO #markdown
		SELECT CONCAT(''* ['', OBJECT_SCHEMA_NAME(object_id), ''.'', OBJECT_NAME(object_id), ''](#'', REPLACE(LOWER(OBJECT_SCHEMA_NAME(object_id)), '' '', ''-''), REPLACE(LOWER(OBJECT_NAME(object_id)), '' '', ''-''), '')'')
		FROM [sys].[objects]
		WHERE [is_ms_shipped] = 0
			AND [type] = ''IF'' --SQL_INLINE_TABLE_VALUED_FUNCTION
		ORDER BY OBJECT_SCHEMA_NAME(object_id), [name] ASC;' +

		--Object details
		+ N'DECLARE obj_cursor CURSOR
		LOCAL STATIC READ_ONLY FORWARD_ONLY
		FOR
		SELECT [object_id]
		FROM [sys].[objects]
		WHERE [is_ms_shipped] = 0
			AND [type] = ''IF'' --SQL_INLINE_TABLE_VALUED_FUNCTION
		ORDER BY OBJECT_SCHEMA_NAME([object_id]), [name] ASC;

		OPEN obj_cursor
		FETCH NEXT FROM obj_cursor INTO @ObjectId
		WHILE @@FETCH_STATUS = 0
		BEGIN

			INSERT INTO #markdown
			SELECT CONCAT(CHAR(13), CHAR(10), ''### '', OBJECT_SCHEMA_NAME(@ObjectId), ''.'', OBJECT_NAME(@ObjectId));' +

			--Main Extended Property (@ExtendedProperty)
			+ N'
			IF EXISTS (SELECT * FROM [sys].[objects] AS [o]
						INNER JOIN [sys].[extended_properties] AS [ep] ON [o].[object_id] = [ep].[major_id]
						WHERE [o].[object_id] = @ObjectId
							AND [ep].[minor_id] = 0 --On the table
							AND [ep].[name] = @ExtendedPropertyName)
				BEGIN;
					INSERT INTO #markdown (value)
					VALUES (CONCAT(CHAR(13), CHAR(10), ''| '', @ExtendedPropertyName COLLATE DATABASE_DEFAULT, '' |''))
					,(''| --- |'');

					INSERT INTO #markdown (value)
					SELECT CONCAT(''| '', REPLACE(REPLACE(REPLACE(REPLACE(CAST([ep].[value] AS NVARCHAR(4000)), ''|'', @PipeHTMLCode COLLATE DATABASE_DEFAULT), CHAR(13) + CHAR(10), @BreakHTMLCode COLLATE DATABASE_DEFAULT), ''`'', @TickHTMLCode COLLATE DATABASE_DEFAULT), '']'', @RightBracketHTMLCode COLLATE DATABASE_DEFAULT), '' |'')
					FROM [sys].[objects] AS [o]
						INNER JOIN [sys].[extended_properties] AS [ep] ON [o].[object_id] = [ep].[major_id]
					WHERE [o].[object_id] = @ObjectId
						AND [ep].[minor_id] = 0
						AND [ep].[name] = @ExtendedPropertyName;
				END;';

			--All Extended Properties (non-@ExtendedProperty)
			IF @AllExtendedProperties = 1
				BEGIN
					SET @Sql = @Sql + N'
					IF EXISTS (SELECT * FROM [sys].[objects] AS [o]
											INNER JOIN [sys].[extended_properties] AS [ep] ON [o].[object_id] = [ep].[major_id]
										WHERE [o].[object_id] = @ObjectId
											AND [ep].[minor_id] = 0
											AND [ep].[name] NOT IN (
												SELECT [param].[name] FROM [sys].[objects] AS [o]
													INNER JOIN [sys].[parameters] AS [param] ON [param].[object_id] = [o].[object_id]
												WHERE [o].[object_id] = @ObjectId)
											AND [ep].[name] <> @ExtendedPropertyName)
					BEGIN;
						INSERT INTO #markdown (value)
						VALUES (CONCAT(CHAR(13), CHAR(10), ''#### '', ''Extended Properties''))
						,(CONCAT(CHAR(13), CHAR(10), ''| Name | Value |''))
						,(''| --- | --- |'');

						INSERT INTO #markdown (value)
						SELECT CONCAT(''| '', [ep].[name], '' | '', REPLACE(REPLACE(REPLACE(REPLACE(CAST([ep].[value] AS NVARCHAR(4000)), ''|'', @PipeHTMLCode COLLATE DATABASE_DEFAULT), CHAR(13) + CHAR(10), @BreakHTMLCode COLLATE DATABASE_DEFAULT), ''`'', @TickHTMLCode COLLATE DATABASE_DEFAULT), '']'', @RightBracketHTMLCode COLLATE DATABASE_DEFAULT), '' |'')
						FROM [sys].[objects] AS [o]
							INNER JOIN [sys].[extended_properties] AS [ep] ON [o].[object_id] = [ep].[major_id]
						WHERE [o].[object_id] = @ObjectId
							AND [ep].[minor_id] = 0
							AND [ep].[name] <> @ExtendedPropertyName
							AND [ep].[name] NOT IN (
									SELECT [param].[name] FROM [sys].[objects] AS [o]
										INNER JOIN [sys].[parameters] AS [param] ON [param].[object_id] = [o].[object_id]
									WHERE [o].[object_id] = @ObjectId)
						ORDER BY [ep].[name] ASC;
					END;';
				END

			--Check for parameters
			SET @Sql = @Sql + N'
			IF EXISTS (SELECT * FROM [sys].[parameters] AS [param] WHERE [param].[object_id] = @ObjectId)
			BEGIN
				INSERT INTO #markdown (value)
				VALUES (CONCAT(CHAR(13), CHAR(10), ''#### '', ''Parameters''))
					,(CONCAT(CHAR(13), CHAR(10), ''| Parameter | Type | Output | Description |''))
					,(''| --- | --- | --- | --- |'');

				INSERT INTO #markdown
				select CONCAT(''| '', CASE WHEN LEN([param].[name]) = 0 THEN ''*Output*'' ELSE [param].[name] END
						,'' | ''
						,CONCAT(UPPER(TYPE_NAME([user_type_id]))
						,CASE
							WHEN TYPE_NAME([user_type_id]) IN (N''decimal'',N''numeric'')
							THEN CONCAT(N''('',CAST(precision AS varchar(5)), N'','',CAST(scale AS varchar(5)), N'')'')
							WHEN TYPE_NAME([user_type_id]) IN (''varchar'', ''char'')
							THEN QUOTENAME(CAST([max_length] AS VARCHAR(10)), ''('')
							WHEN TYPE_NAME([user_type_id]) IN (N''time'',N''datetime2'',N''datetimeoffset'')
							THEN QUOTENAME(CAST(scale AS varchar(5)), ''('')
							WHEN TYPE_NAME([user_type_id]) in (N''float'')
							THEN CASE
								WHEN precision = 53
								THEN N''''
								ELSE QUOTENAME(CAST(precision AS varchar(5)),''('') END
							WHEN TYPE_NAME([user_type_id]) IN (N''int'',N''bigint'',N''smallint'',N''tinyint'',N''money'',N''smallmoney'',
								N''real'',N''datetime'',N''smalldatetime'',N''bit'',N''image'',N''text'',N''uniqueidentifier'',
								N''date'',N''ntext'',N''sql_variant'',N''hierarchyid'',''geography'',N''timestamp'',N''xml'')
							THEN N''''
							ELSE CASE
								WHEN [is_readonly] = 1 --User defined table type
								THEN N''''
								WHEN [max_length] = -1
								THEN N''(MAX)''
								WHEN TYPE_NAME([user_type_id]) IN (N''nvarchar'',N''nchar'', N''sysname'')
								THEN QUOTENAME(CAST([max_length]/2 AS VARCHAR(10)), ''('')
								ELSE QUOTENAME(CAST([max_length] AS VARCHAR(10)), ''('')
								END
						END)
						,'' | ''
						,CASE [is_output]
							WHEN 1
							THEN @Yes
							ELSE @No
							END
						,'' | ''
						,REPLACE(REPLACE(REPLACE(REPLACE(CAST([ep].[value] AS NVARCHAR(4000)), ''|'', @PipeHTMLCode COLLATE DATABASE_DEFAULT), CHAR(13) + CHAR(10), @BreakHTMLCode COLLATE DATABASE_DEFAULT), ''`'', @TickHTMLCode COLLATE DATABASE_DEFAULT), '']'', @RightBracketHTMLCode COLLATE DATABASE_DEFAULT)
						, '' |'')
				FROM [sys].[objects] AS [o]
					INNER JOIN [sys].[parameters] AS [param] ON [param].[object_id] = [o].[object_id]
					LEFT JOIN [sys].[extended_properties] AS [ep] ON [o].[object_id] = [ep].[major_id]
						AND [ep].[name] = [param].[name]
				WHERE [o].[object_id] = @ObjectId
				ORDER BY [param].[parameter_id] ASC;
			END;' +

			--Object definition
			+ N'INSERT INTO #markdown (value)
			VALUES(CONCAT(CHAR(13), CHAR(10), ''#### Definition''))
				,(CONCAT(CHAR(13), CHAR(10), ''<details><summary>Click to expand</summary>''))
				,(CONCAT(CHAR(13), CHAR(10), ''```sql'', CHAR(13), CHAR(10), OBJECT_DEFINITION(@ObjectId)))
				,(''```'')
				,(CONCAT(CHAR(13), CHAR(10), ''</details>''));' +

			--Dependencies
			+ N'IF EXISTS (SELECT 1 FROM [sys].[dm_sql_referencing_entities] (CONCAT(OBJECT_SCHEMA_NAME(@ObjectId), ''.'', OBJECT_NAME(@ObjectId)), ''OBJECT''))
			BEGIN
				INSERT INTO #markdown (value)
				SELECT CONCAT(CHAR(13), CHAR(10), ''#### '', ''Referenced By'');

				INSERT INTO #markdown (value)
				VALUES (CONCAT(CHAR(13), CHAR(10), ''| Object | Type |''))
					,(''| --- | --- |'');

				INSERT INTO #markdown (value)
				SELECT CONCAT(''| ''
						, CONCAT(''['',QUOTENAME([ref].[referencing_schema_name]), ''.'', QUOTENAME([ref].[referencing_entity_name]),'']'',''(#'',LOWER([ref].[referencing_schema_name]), LOWER([ref].[referencing_entity_name]), '')'')
						,'' | ''
						, REPLACE(LOWER([o].[type_desc]), ''_'' COLLATE DATABASE_DEFAULT, '' '' COLLATE DATABASE_DEFAULT)
						, '' |'') COLLATE DATABASE_DEFAULT
				FROM [sys].[dm_sql_referencing_entities] (CONCAT(OBJECT_SCHEMA_NAME(@ObjectId), ''.'', OBJECT_NAME(@ObjectId)), ''OBJECT'') [ref]
					INNER JOIN [sys].[objects] [o] on [o].[object_id] = [ref].[referencing_id]
				WHERE [ref].[referencing_id] <> @ObjectId -- Exclude self-references
				ORDER BY 1;
			END;' +

			--Back to top
			+ N'INSERT INTO #markdown
			VALUES (CONCAT(CHAR(13), CHAR(10),''[Back to top](#'', LOWER(@DatabaseName COLLATE DATABASE_DEFAULT), '')''));

			FETCH NEXT FROM obj_cursor INTO @ObjectId;

		END;
		CLOSE obj_cursor;
		DEALLOCATE obj_cursor;' +

		--End collapsible table functions section
		+ N'INSERT INTO #markdown
		VALUES (CONCAT(CHAR(13), CHAR(10), ''</details>''));
	END;'; --End markdown for table functions

	/******************************
	Generate markdown for synonyms
	******************************/
	--Build table of contents
	SET @Sql = @Sql + N'
	IF EXISTS (SELECT 1 FROM [sys].[synonyms] WHERE [is_ms_shipped] = 0)
	BEGIN;
		INSERT INTO #markdown ([value])
		VALUES (CONCAT(CHAR(13), CHAR(10), ''## Synonyms'')) ,(CONCAT(CHAR(13), CHAR(10), ''<details><summary>Click to expand</summary>'', CHAR(13), CHAR(10)));
		' +

		+ N'INSERT INTO #markdown
		SELECT CONCAT(''* ['', OBJECT_SCHEMA_NAME(object_id), ''.'', OBJECT_NAME(object_id), ''](#'', REPLACE(LOWER(OBJECT_SCHEMA_NAME(object_id)), '' '', ''-''), REPLACE(LOWER(OBJECT_NAME(object_id)), '' '', ''-''), '')'')
		FROM [sys].[synonyms]
		WHERE [is_ms_shipped] = 0
		ORDER BY OBJECT_SCHEMA_NAME([object_id]), [name] ASC;' +

		--Object details
		+ N'DECLARE obj_cursor CURSOR
		LOCAL STATIC READ_ONLY FORWARD_ONLY
		FOR
		SELECT [object_id]
		FROM [sys].[synonyms]
		WHERE [is_ms_shipped] = 0
		ORDER BY OBJECT_SCHEMA_NAME([object_id]), [name] ASC;

		OPEN obj_cursor
		FETCH NEXT FROM obj_cursor INTO @ObjectId
		WHILE @@FETCH_STATUS = 0
		BEGIN

			INSERT INTO #markdown
			SELECT CONCAT(CHAR(13), CHAR(10), ''### '', OBJECT_SCHEMA_NAME(@ObjectId), ''.'', OBJECT_NAME(@ObjectId), CHAR(13), CHAR(10)); ' +

			--Main Extended Property (@ExtendedProperty)
			+ N'
			IF EXISTS (SELECT * FROM [sys].[synonyms] AS [s]
						INNER JOIN [sys].[extended_properties] AS [ep] ON [s].[object_id] = [ep].[major_id]
						WHERE [s].[object_id] = @ObjectId
							AND [ep].[minor_id] = 0 --On the object
							AND [ep].[name] = @ExtendedPropertyName)
			BEGIN;
				INSERT INTO #markdown (value)
				VALUES (CONCAT(CHAR(13), CHAR(10), ''| '', @ExtendedPropertyName COLLATE DATABASE_DEFAULT, '' |''))
				,(''| --- |'');

				INSERT INTO #markdown (value)
				SELECT CONCAT(''| '', REPLACE(REPLACE(REPLACE(REPLACE(CAST([ep].[value] AS NVARCHAR(4000)), ''|'', @PipeHTMLCode COLLATE DATABASE_DEFAULT), CHAR(13) + CHAR(10), @BreakHTMLCode COLLATE DATABASE_DEFAULT), ''`'', @TickHTMLCode COLLATE DATABASE_DEFAULT), '']'', @RightBracketHTMLCode COLLATE DATABASE_DEFAULT), '' |'')
				FROM [sys].[synonyms] AS [s]
					INNER JOIN [sys].[extended_properties] AS [ep] ON [s].[object_id] = [ep].[major_id]
				WHERE [s].[object_id] = @ObjectId
					AND [ep].[minor_id] = 0 --On the object
					AND [ep].[name] = @ExtendedPropertyName;
			END;';

			--All Extended Properties (non-@ExtendedProperty)
			IF @AllExtendedProperties = 1
				BEGIN;
					SET @Sql = @Sql + N'
					IF EXISTS (SELECT * FROM [sys].[synonyms] AS [s]
						INNER JOIN [sys].[extended_properties] AS [ep] ON [s].[object_id] = [ep].[major_id]
						WHERE [s].[object_id] = @ObjectId
							AND [ep].[minor_id] = 0
							AND [ep].[name] <> @ExtendedPropertyName)
					BEGIN;
						INSERT INTO #markdown (value)
						VALUES (CONCAT(CHAR(13), CHAR(10), ''#### '', ''Extended Properties''))
						,(CONCAT(CHAR(13), CHAR(10), ''| Name | Value |''))
						,(''| --- | --- |'');

						INSERT INTO #markdown (value)
						SELECT CONCAT(''| '', [ep].[name], '' | '', REPLACE(REPLACE(REPLACE(REPLACE(CAST([ep].[value] AS NVARCHAR(4000)), ''|'', @PipeHTMLCode COLLATE DATABASE_DEFAULT), CHAR(13) + CHAR(10), @BreakHTMLCode COLLATE DATABASE_DEFAULT), ''`'', @TickHTMLCode COLLATE DATABASE_DEFAULT), '']'', @RightBracketHTMLCode COLLATE DATABASE_DEFAULT), '' |'')
						FROM [sys].[synonyms] AS [s]
							INNER JOIN [sys].[extended_properties] AS [ep] ON [s].[object_id] = [ep].[major_id]
						WHERE [s].[object_id] = @ObjectId
							AND [ep].[minor_id] = 0
							AND [ep].[name] <> @ExtendedPropertyName
						ORDER BY [ep].[name] ASC;
					END;';
				END;

			--Object mapping
			SET @Sql = @Sql + N'
			INSERT INTO #markdown (value)
				VALUES (CONCAT(CHAR(13), CHAR(10), ''#### '', ''Object Mapping''))
				,(CONCAT(CHAR(13), CHAR(10), ''| Synonym | Base Object |''))
				,(''| --- | --- |'');

			INSERT INTO #markdown
			SELECT CONCAT(''| '', OBJECT_SCHEMA_NAME([syn].[object_id]), ''.'', OBJECT_NAME([syn].[object_id])
					,'' | ''
					,CASE WHEN PARSENAME([base_object_name], 3) = DB_NAME()
						THEN CONCAT(''['', QUOTENAME(PARSENAME([base_object_name], 3)), ''.'', QUOTENAME(PARSENAME([base_object_name], 2)), ''.'', QUOTENAME(PARSENAME([base_object_name], 1)), '']'', ''(#'', PARSENAME([base_object_name], 2), PARSENAME([base_object_name], 1), '')'')
						ELSE CONCAT(QUOTENAME(PARSENAME([base_object_name], 3)), QUOTENAME(PARSENAME([base_object_name], 2)), QUOTENAME(PARSENAME([base_object_name], 1)))
					END
					,'' |'')
				FROM [sys].[synonyms] AS [syn]
				WHERE [syn].[object_id] = @ObjectId;' +

			--Dependencies
			--Synonyms must use dm_sql_referenced_entities instead of dm_sql_referencing_entities
			--and use additional error handling for Msg 2020 workaround
			--https://git.io/JcOsN
			+ N'DECLARE @SynonymDependencyExists BIT;

			BEGIN TRY
				SET @SynonymDependencyExists = (SELECT 1 FROM [sys].[objects] [o]
										CROSS APPLY [sys].[dm_sql_referenced_entities] (CONCAT(SCHEMA_NAME(o.schema_id), ''.'', OBJECT_NAME(o.object_id)), ''OBJECT'') [ref]
										WHERE [ref].[referenced_class] = 1 --Type
											AND [ref].[referenced_id] = @ObjectId
											AND [o].[is_ms_shipped] = 0);
			END TRY
			BEGIN CATCH
				IF (1=0)
					SELECT ''SayTheirNames'';
			END CATCH

			IF (@SynonymDependencyExists = 1)
			BEGIN
				INSERT INTO #markdown (value)
				SELECT CONCAT(CHAR(13), CHAR(10), ''#### '', ''Referenced By'');

				INSERT INTO #markdown (value)
				VALUES (CONCAT(CHAR(13), CHAR(10), ''| Object | Type |''))
					,(''| --- | --- |'');

				BEGIN TRY;
				INSERT INTO #markdown (value)
				SELECT CONCAT(''| ''
						, CONCAT(''['',QUOTENAME(SCHEMA_NAME([o].[schema_id])), ''.'', QUOTENAME([o].[name]),'']'',''(#'',LOWER(SCHEMA_NAME([o].[schema_id])), LOWER([o].[name]), '')'')
						,'' | ''
						, REPLACE(LOWER([o].[type_desc]), ''_'' COLLATE DATABASE_DEFAULT, '' '' COLLATE DATABASE_DEFAULT)
						, '' |'') COLLATE DATABASE_DEFAULT
				FROM [sys].[objects] [o]
					CROSS APPLY [sys].[dm_sql_referenced_entities] (CONCAT(SCHEMA_NAME([o].[schema_id]), ''.'', OBJECT_NAME([o].[object_id])), ''OBJECT'') [ref]
				WHERE [ref].[referenced_class] = 1 --Object
					AND [ref].[referenced_id] = @ObjectId
					AND [o].[is_ms_shipped] = 0
				ORDER BY 1;
				END TRY
				BEGIN CATCH;
					IF (1=0)
						SELECT ''SayTheirNames'';
				END CATCH;
			END;' +

			--Back to top
			+ N'INSERT INTO #markdown
			VALUES (CONCAT(CHAR(13), CHAR(10),''[Back to top](#'', LOWER(@DatabaseName COLLATE DATABASE_DEFAULT), '')''));

			FETCH NEXT FROM obj_cursor INTO @ObjectId

		END
		CLOSE obj_cursor
		DEALLOCATE obj_cursor;' +

		--End collapsible synonyms section
		+ N'INSERT INTO #markdown
		VALUES (CONCAT(CHAR(13), CHAR(10), ''</details>''));
	END;'; --End markdown for synonyms

	/***********************************************
	Generate markdown for user defined table types
	***********************************************/
	--Build table of contents
	SET @Sql = @Sql + N'
	IF EXISTS (SELECT 1 FROM [sys].[table_types] WHERE [is_user_defined] = 1)
	BEGIN
		INSERT INTO #markdown (value)
		VALUES (CONCAT(CHAR(13), CHAR(10), ''## User Defined Table Types''))
			,(CONCAT(CHAR(13), CHAR(10), ''<details><summary>Click to expand</summary>'', CHAR(13), CHAR(10)));
		' +

		+ N'INSERT INTO #markdown (value)
		SELECT CONCAT(''* ['', SCHEMA_NAME([schema_id]), ''.'', [name], ''](#'', REPLACE(LOWER(SCHEMA_NAME([schema_id])), '' '', ''-''), REPLACE(LOWER([name]), '' '', ''-''), '')'')
		FROM [sys].[table_types]
		WHERE [is_user_defined] = 1
		ORDER BY OBJECT_SCHEMA_NAME([user_type_id]), [name] ASC;' +

		--Object details
		+ N'DECLARE obj_cursor CURSOR
		LOCAL STATIC READ_ONLY FORWARD_ONLY
		FOR
		SELECT [user_type_id]
		FROM [sys].[table_types]
		WHERE [is_user_defined] = 1
		ORDER BY OBJECT_SCHEMA_NAME([user_type_id]), [name] ASC;

		OPEN obj_cursor
		FETCH NEXT FROM obj_cursor INTO @ObjectId
		WHILE @@FETCH_STATUS = 0
		BEGIN

			DECLARE @UserTypeID INT = @ObjectId;

			INSERT INTO #markdown
			SELECT CONCAT(CHAR(13), CHAR(10), ''### '', SCHEMA_NAME([schema_id]), ''.'', [name])
			FROM [sys].[table_types]
			WHERE [user_type_id] = @UserTypeID
				AND [is_user_defined] = 1;' +

			--Main Extended Property (@ExtendedProperty)
			+ N'
			IF EXISTS (SELECT * FROM [sys].[table_types] AS [tt]
						INNER JOIN [sys].[extended_properties] AS [ep] ON [tt].[user_type_id] = [ep].[major_id]
						WHERE [tt].[user_type_id] = @UserTypeID
							AND [ep].[minor_id] = 0 --On the table
							AND [tt].[is_user_defined] = 1
							AND [ep].[name] = @ExtendedPropertyName)
				BEGIN;
					INSERT INTO #markdown (value)
					VALUES (CONCAT(CHAR(13), CHAR(10), ''| '', @ExtendedPropertyName COLLATE DATABASE_DEFAULT, '' |''))
					,(''| --- |'');

					INSERT INTO #markdown (value)
					SELECT CONCAT(''| '', REPLACE(REPLACE(REPLACE(REPLACE(CAST([ep].[value] AS NVARCHAR(4000)), ''|'', @PipeHTMLCode COLLATE DATABASE_DEFAULT), CHAR(13) + CHAR(10), @BreakHTMLCode COLLATE DATABASE_DEFAULT), ''`'', @TickHTMLCode COLLATE DATABASE_DEFAULT), '']'', @RightBracketHTMLCode COLLATE DATABASE_DEFAULT), '' |'')
					FROM [sys].[table_types] AS [tt]
						INNER JOIN [sys].[extended_properties] AS [ep] ON [tt].[user_type_id] = [ep].[major_id]
					WHERE [tt].[user_type_id] = @UserTypeID
						AND [ep].[minor_id] = 0 --On the table
						AND [ep].[name] = @ExtendedPropertyName
						AND [tt].[is_user_defined] = 1;
				END;';

			--All Extended Properties (non-@ExtendedProperty)
			IF @AllExtendedProperties = 1
				BEGIN;
					SET @Sql = @Sql + N'
					IF EXISTS (SELECT * FROM [sys].[table_types] AS [tt]
						INNER JOIN [sys].[extended_properties] AS [ep] ON [tt].[user_type_id] = [ep].[major_id]
						WHERE [tt].[user_type_id] = @UserTypeID
							AND [ep].[minor_id] = 0 --On the table
							AND [tt].[is_user_defined] = 1
							AND [ep].[name] <> @ExtendedPropertyName)
					BEGIN;
						INSERT INTO #markdown (value)
						VALUES (CONCAT(CHAR(13), CHAR(10), ''#### '', ''Extended Properties''))
						,(CONCAT(CHAR(13), CHAR(10), ''| Name | Value |''))
						,(''| --- | --- |'');

						INSERT INTO #markdown (value)
						SELECT CONCAT(''| '', [ep].[name], '' | '', REPLACE(REPLACE(REPLACE(REPLACE(CAST([ep].[value] AS NVARCHAR(4000)), ''|'', @PipeHTMLCode COLLATE DATABASE_DEFAULT), CHAR(13) + CHAR(10), @BreakHTMLCode COLLATE DATABASE_DEFAULT), ''`'', @TickHTMLCode COLLATE DATABASE_DEFAULT), '']'', @RightBracketHTMLCode COLLATE DATABASE_DEFAULT), '' |'')
						FROM [sys].[table_types] AS [tt]
							INNER JOIN [sys].[extended_properties] AS [ep] ON [tt].[user_type_id] = [ep].[major_id]
						WHERE [tt].[user_type_id] = @UserTypeID
							AND [ep].[minor_id] = 0 --On the table
							AND [ep].[name] <> @ExtendedPropertyName
							AND [tt].[is_user_defined] = 1
						ORDER BY [ep].[name] ASC;
					END;';
				END;

			--Columns
			SET @Sql = @Sql + N'
			INSERT INTO #markdown (value)
			VALUES (CONCAT(CHAR(13), CHAR(10), ''#### '', ''Columns''))
				,(CONCAT(CHAR(13), CHAR(10), ''| Column | Type | Null | Default | '', @ExtendedPropertyName COLLATE DATABASE_DEFAULT, '' |''))
				,(''| --- | ---| --- | --- | --- |'');

			INSERT INTO #markdown (value)
			SELECT CONCAT(''| ''
                    ,CASE
                        WHEN [ic].[object_id] IS NOT NULL
                        THEN CONCAT(@PK, ''**'',[c].[name],''**'')
                        ELSE CONCAT(@Column, [c].[name])
                    END
					,'' | ''
					,CONCAT(UPPER(TYPE_NAME([c].[user_type_id]))
					,CASE
							WHEN TYPE_NAME([c].[user_type_id]) IN (N''decimal'',N''numeric'')
							THEN CONCAT(N''('',CAST([c].[precision] AS VARCHAR(5)), N'','',CAST([c].[scale] AS varchar(5)), N'')'')
							WHEN TYPE_NAME([c].[user_type_id]) IN (''varchar'', ''char'', ''varbinary'')
							THEN CASE
									WHEN [c].[max_length] = -1
									THEN N''(MAX)''
									ELSE QUOTENAME(CAST([c].[max_length] AS VARCHAR(10)), ''('')
								END
							WHEN TYPE_NAME([c].[user_type_id]) IN (N''time'',N''datetime2'',N''datetimeoffset'')
							THEN QUOTENAME(CAST([c].[scale] AS VARCHAR(5)), ''('')
							WHEN TYPE_NAME([c].[user_type_id]) in (N''float'')
							THEN CASE
									WHEN [c].precision = 53
									THEN N''''
									ELSE CONCAT(N''('',CAST([c].[precision] AS VARCHAR(5)),N'')'')
								END
							WHEN TYPE_NAME([c].[user_type_id]) IN (N''int'',N''bigint'',N''smallint'',N''tinyint'',N''money'',N''smallmoney'',
								N''real'',N''datetime'',N''smalldatetime'',N''bit'',N''image'',N''text'',N''uniqueidentifier'',
								N''date'',N''ntext'',N''sql_variant'',N''hierarchyid'',''geography'',N''timestamp'',N''xml'')
							THEN N''''
							WHEN TYPE_NAME([c].[user_type_id]) IN (N''nvarchar'',N''nchar'', N''sysname'')
							THEN CASE
									WHEN [c].[max_length] = -1
									THEN N''(MAX)''
									ELSE QUOTENAME(CAST([c].[max_length]/2 AS VARCHAR(10)), ''('')
								END
							ELSE QUOTENAME(CAST([c].[max_length] AS VARCHAR(10)), ''('')
					END)
					,'' | ''
					,CASE [c].[is_nullable]
						WHEN 1
						THEN @Yes
						ELSE @No
						END
					,'' | ''
					,OBJECT_DEFINITION([dc].[object_id])
					,'' | ''
					,REPLACE(REPLACE(REPLACE(REPLACE(CAST([ep].[value] AS NVARCHAR(4000)), ''|'', @PipeHTMLCode COLLATE DATABASE_DEFAULT), CHAR(13) + CHAR(10), @BreakHTMLCode COLLATE DATABASE_DEFAULT), ''`'', @TickHTMLCode COLLATE DATABASE_DEFAULT), '']'', @RightBracketHTMLCode COLLATE DATABASE_DEFAULT)
					,'' |'')
			FROM [sys].[table_types] AS [tt]
				INNER JOIN [sys].[columns] AS [c] ON [tt].[type_table_object_id] = [c].[object_id]
				LEFT JOIN [sys].[extended_properties] AS [ep] ON [tt].[user_type_id] = [ep].[major_id]
					AND [ep].[minor_id] > 0
					AND [ep].[minor_id] = [c].[column_id]
					AND [ep].[class] = 8 --UDTT Columns
					AND [ep].[name] = @ExtendedPropertyName
				LEFT JOIN [sys].[default_constraints] [dc] ON [dc].[parent_object_id] = [c].[object_id]
					AND [dc].[parent_column_id] = [c].[column_id]
				LEFT JOIN [sys].[indexes] AS [pk] ON [pk].[object_id] = [tt].[type_table_object_id]
					AND [pk].[is_primary_key] = 1
				LEFT JOIN [sys].[index_columns] AS [ic] ON [ic].[index_id] = [pk].[index_id]
					AND [ic].[object_id] = [tt].[type_table_object_id]
					AND [ic].[column_id] = [c].[column_id]
			WHERE [tt].[user_type_id] = @UserTypeID
				AND [tt].[is_user_defined] = 1;';

			--UDTT Column Extended Properties
			IF @AllExtendedProperties = 1
				BEGIN
					SET @Sql = @Sql + N'
					IF EXISTS (SELECT * FROM [sys].[table_types] AS [tt]
											INNER JOIN [sys].[columns] AS [c] ON [tt].[type_table_object_id] = [c].[object_id]
											INNER JOIN [sys].[extended_properties] AS [ep] ON [tt].[user_type_id] = [ep].[major_id]
												AND [ep].[minor_id] > 0
												AND [ep].[minor_id] = [c].[column_id]
												AND [ep].[class] = 8 --UDTT Columns
												AND [ep].[name] <> @ExtendedPropertyName
										WHERE [tt].[user_type_id] = @UserTypeID
											AND [tt].[is_user_defined] = 1)
					BEGIN
						INSERT INTO #markdown (value)
						VALUES (CONCAT(CHAR(13), CHAR(10), ''##### '', ''Column Extended Properties''))
						,(CONCAT(CHAR(13), CHAR(10), ''Column | Name | Value |''))
						,(''| --- | --- | --- |'');

						INSERT INTO #markdown (value)
						SELECT CONCAT(''| '', [c].[name], '' | '', [ep].[name], '' | '', REPLACE(REPLACE(REPLACE(REPLACE(CAST([ep].[value] AS NVARCHAR(4000)), ''|'', @PipeHTMLCode COLLATE DATABASE_DEFAULT), CHAR(13) + CHAR(10), @BreakHTMLCode COLLATE DATABASE_DEFAULT), ''`'', @TickHTMLCode COLLATE DATABASE_DEFAULT), '']'', @RightBracketHTMLCode COLLATE DATABASE_DEFAULT) COLLATE DATABASE_DEFAULT, '' |'')
						FROM [sys].[table_types] AS [tt]
							INNER JOIN [sys].[columns] AS [c] ON [tt].[type_table_object_id] = [c].[object_id]
							INNER JOIN [sys].[extended_properties] AS [ep] ON [tt].[user_type_id] = [ep].[major_id]
								AND [ep].[minor_id] > 0
								AND [ep].[minor_id] = [c].[column_id]
								AND [ep].[class] = 8 --UDTT Columns
								AND [ep].[name] <> @ExtendedPropertyName
						WHERE [tt].[user_type_id] = @UserTypeID
							AND [tt].[is_user_defined] = 1
						ORDER BY [c].[name], [ep].[name] ASC;
					END;';
				END

			--Dependencies
			--UDTT must use dm_sql_referenced_entities instead of dm_sql_referencing_entities
			--and use additional error handling for Msg 2020 workaround
			--https://git.io/JcOsN
			SET @Sql = @Sql + N'
			DECLARE @UDTTDependencyExists BIT;

			BEGIN TRY;
				SET @UDTTDependencyExists = (SELECT 1 FROM [sys].[objects] [o]
										CROSS APPLY [sys].[dm_sql_referenced_entities] (CONCAT(SCHEMA_NAME(o.schema_id), ''.'', OBJECT_NAME(o.object_id)), ''OBJECT'') [ref]
										WHERE [ref].[referenced_class] = 6 --Type
											AND [ref].[referenced_id] = @UserTypeID
											AND [o].[is_ms_shipped] = 0);
			END TRY
			BEGIN CATCH;
				IF (1=0)
					SELECT ''SayTheirNames'';
			END CATCH;

			IF (@UDTTDependencyExists = 1)
			BEGIN
				INSERT INTO #markdown (value)
				SELECT CONCAT(CHAR(13), CHAR(10), ''#### '', ''Referenced By'');

				BEGIN TRY
				INSERT INTO #markdown (value)
				VALUES (CONCAT(CHAR(13), CHAR(10), ''| Object | Type |''))
					,(''| --- | --- |'');

				INSERT INTO #markdown (value)
				SELECT CONCAT(''| ''
						, CONCAT(''['',QUOTENAME(SCHEMA_NAME([o].[schema_id])), ''.'', QUOTENAME([o].[name]),'']'',''(#'',LOWER(SCHEMA_NAME([o].[schema_id])), LOWER([o].[name]), '')'')
						,'' | ''
						, REPLACE(LOWER([o].[type_desc]), ''_'' COLLATE DATABASE_DEFAULT, '' '' COLLATE DATABASE_DEFAULT)
						, '' |'') COLLATE DATABASE_DEFAULT
				FROM [sys].[objects] [o]
					CROSS APPLY [sys].[dm_sql_referenced_entities] (CONCAT(SCHEMA_NAME([o].[schema_id]), ''.'', OBJECT_NAME([o].[object_id])), ''OBJECT'') [ref]
				WHERE [ref].[referenced_class] = 6 --Type
					AND [ref].[referenced_id] = @UserTypeID
					AND [o].[is_ms_shipped] = 0
				ORDER BY 1;
				END TRY
				BEGIN CATCH
					IF (1=0)
						SELECT ''SayTheirNames'';
				END CATCH
			END;' +

			--Back to top
			+ N'INSERT INTO #markdown
			VALUES (CONCAT(CHAR(13), CHAR(10), ''[Back to top](#'', LOWER(@DatabaseName COLLATE DATABASE_DEFAULT), '')''))

			FETCH NEXT FROM obj_cursor INTO @ObjectId;

		END;
		CLOSE obj_cursor;
		DEALLOCATE obj_cursor;' +

		--End collapsible table section
		+ N'INSERT INTO #markdown
		VALUES (CONCAT(CHAR(13), CHAR(10), ''</details>''));
	END;'; --End markdown for user defined table types

	--Attribution
	SET @Sql = @Sql + N'INSERT INTO #markdown
	VALUES (CONCAT(CHAR(13), CHAR(10), ''----''))
		,(CONCAT(CHAR(13), CHAR(10), ''*Markdown generated by [sp_doc](https://dba-multitool.org)''))
		,(CONCAT('' at '', SYSDATETIMEOFFSET(), ''.*''));';

	--Return all data
	SET @Sql = @Sql + N'
	SELECT [value]
	FROM #markdown
	ORDER BY [ID] ASC;';

	SET @ParmDefinition = N'@ExtendedPropertyName SYSNAME
		,@DatabaseName SYSNAME
		,@LimitStoredProcLength BIT
		,@Yes VARCHAR(20)
		,@No VARCHAR(20)
		,@PK VARCHAR(20)
		,@FK VARCHAR(20)
		,@Column VARCHAR(20)
		,@PipeHTMLCode CHAR(6)
		,@TickHTMLCode CHAR(5)
		,@RightBracketHTMLCode CHAR(5)
		,@BreakHTMLCode CHAR(5)';
	EXEC sp_executesql @Sql
		,@ParmDefinition
		,@ExtendedPropertyName
		,@DatabaseName
		,@LimitStoredProcLength
		,@Yes
		,@No
		,@PK
		,@FK
		,@Column
		,@PipeHTMLCode
		,@TickHTMLCode
		,@RightBracketHTMLCode
		,@BreakHTMLCode;
END;
GO

EXEC sys.sp_addextendedproperty @name=N'Description', @value=N'Generate on the fly database documentation in markdown. Documentation at https://expresssql.lowlydba.com' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'sp_doc';
GO

EXEC sys.sp_addextendedproperty @name=N'@DatabaseName', @value=N'Target database to document. Default is the stored procedure''s database.' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'sp_doc';
GO

EXEC sys.sp_addextendedproperty @name=N'@ExtendedPropertyName', @value=N'Key for extended properties on objects. Default is ''Description''.' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'sp_doc';
GO

EXEC sys.sp_addextendedproperty @name=N'@SqlMajorVersion', @value=N'Used for unit testing purposes only.' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'sp_doc';
GO

EXEC sys.sp_addextendedproperty @name=N'@SqlMinorVersion', @value=N'Used for unit testing purposes only.' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'sp_doc';
GO

EXEC sys.sp_addextendedproperty @name=N'@LimitStoredProcLength', @value=N'Limit stored procedure contents to 8000 characters, to avoid memory issues with some IDEs. Default is 1.' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'sp_doc';
GO

EXEC sys.sp_addextendedproperty @name=N'@Emojis', @value=N'Use emojis when generating documentation. Default is 0.' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'sp_doc';
GO

EXEC sys.sp_addextendedproperty @name=N'@Verbose', @value=N'Whether or not to print additional information during the script run. Default is 0.' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'sp_doc';
GO

EXEC sys.sp_addextendedproperty @name=N'@AllExtendedProperties', @value=N'Include all extended properties for each object, not just @ExtendedPropertyName.' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'sp_doc';
GO
SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

IF  EXISTS (SELECT * FROM sys.fn_listextendedproperty(N'Description' , N'SCHEMA',N'dbo', N'PROCEDURE',N'sp_estindex', NULL,NULL))
    BEGIN;
        EXEC sys.sp_dropextendedproperty @name=N'Description' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'sp_estindex';
    END;
GO

IF  EXISTS (SELECT * FROM sys.fn_listextendedproperty(N'@TableName' , N'SCHEMA',N'dbo', N'PROCEDURE',N'sp_estindex', NULL,NULL))
    BEGIN;
        EXEC sys.sp_dropextendedproperty @name=N'@TableName' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'sp_estindex';
    END;
GO

IF  EXISTS (SELECT * FROM sys.fn_listextendedproperty(N'@SqlMajorVersion' , N'SCHEMA',N'dbo', N'PROCEDURE',N'sp_estindex', NULL,NULL))
    BEGIN;
        EXEC sys.sp_dropextendedproperty @name=N'@SqlMajorVersion' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'sp_estindex';
    END;
GO

IF  EXISTS (SELECT * FROM sys.fn_listextendedproperty(N'@SchemaName' , N'SCHEMA',N'dbo', N'PROCEDURE',N'sp_estindex', NULL,NULL))
    BEGIN;
        EXEC sys.sp_dropextendedproperty @name=N'@SchemaName' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'sp_estindex';
    END;
GO

IF  EXISTS (SELECT * FROM sys.fn_listextendedproperty(N'@IsUnique' , N'SCHEMA',N'dbo', N'PROCEDURE',N'sp_estindex', NULL,NULL))
    BEGIN;
        EXEC sys.sp_dropextendedproperty @name=N'@IsUnique' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'sp_estindex';
    END;
GO

IF  EXISTS (SELECT * FROM sys.fn_listextendedproperty(N'@IndexColumns' , N'SCHEMA',N'dbo', N'PROCEDURE',N'sp_estindex', NULL,NULL))
    BEGIN;
        EXEC sys.sp_dropextendedproperty @name=N'@IndexColumns' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'sp_estindex';
    END;
GO

IF  EXISTS (SELECT * FROM sys.fn_listextendedproperty(N'@IncludeColumns' , N'SCHEMA',N'dbo', N'PROCEDURE',N'sp_estindex', NULL,NULL))
    BEGIN;
        EXEC sys.sp_dropextendedproperty @name=N'@IncludeColumns' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'sp_estindex';
    END;
GO

IF  EXISTS (SELECT * FROM sys.fn_listextendedproperty(N'@Filter' , N'SCHEMA',N'dbo', N'PROCEDURE',N'sp_estindex', NULL,NULL))
    BEGIN;
        EXEC sys.sp_dropextendedproperty @name=N'@Filter' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'sp_estindex';
    END;
GO

IF  EXISTS (SELECT * FROM sys.fn_listextendedproperty(N'@FillFactor' , N'SCHEMA',N'dbo', N'PROCEDURE',N'sp_estindex', NULL,NULL))
    BEGIN;
        EXEC sys.sp_dropextendedproperty @name=N'@FillFactor' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'sp_estindex';
    END;
GO

IF  EXISTS (SELECT * FROM sys.fn_listextendedproperty(N'@VarcharFillPercent' , N'SCHEMA',N'dbo', N'PROCEDURE',N'sp_estindex', NULL,NULL))
    BEGIN;
        EXEC sys.sp_dropextendedproperty @name=N'@VarcharFillPercent' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'sp_estindex';
    END;
GO

IF  EXISTS (SELECT * FROM sys.fn_listextendedproperty(N'@DatabaseName' , N'SCHEMA',N'dbo', N'PROCEDURE',N'sp_estindex', NULL,NULL))
    BEGIN;
        EXEC sys.sp_dropextendedproperty @name=N'@DatabaseName' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'sp_estindex';
    END;
GO

IF  EXISTS (SELECT * FROM sys.fn_listextendedproperty(N'@Verbose' , N'SCHEMA',N'dbo', N'PROCEDURE',N'sp_estindex', NULL,NULL))
    BEGIN;
        EXEC sys.sp_dropextendedproperty @name=N'@Verbose' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'sp_estindex';
    END;
GO

/***************************/
/* Create stored procedure */
/***************************/
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_estindex]') AND [type] IN (N'P', N'PC'))
	BEGIN;
		EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[sp_estindex] AS';
	END
GO

ALTER PROCEDURE [dbo].[sp_estindex]
    @SchemaName SYSNAME = NULL
    ,@TableName SYSNAME
    ,@DatabaseName SYSNAME = NULL
    ,@IndexColumns NVARCHAR(2048)
    ,@IncludeColumns NVARCHAR(2048) = NULL
    ,@IsUnique BIT = 0
    ,@Filter NVARCHAR(2048) = ''
    ,@FillFactor TINYINT = 100
    ,@VarcharFillPercent TINYINT = 100
    ,@Verbose BIT = 0
    -- Unit testing only
    ,@SqlMajorVersion TINYINT = 0
AS
BEGIN

SET NOCOUNT ON;

/*
sp_estindex - Estimate a new index's size and statistics.

Part of the DBA MultiTool http://dba-multitool.org

Version: 20220124

MIT License

Copyright (c) 2023 John McCall

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

-- TODO:
    -- Handle clustered indexes - https://docs.microsoft.com/en-us/sql/relational-databases/databases/estimate-the-size-of-a-clustered-index?view=sql-server-ver15

=========

Example:

    EXEC dbo.sp_estindex @SchemaName = 'dbo', @tableName = 'Marathon', @IndexColumns = 'racer_id, finish_time, is_disqualified';

    EXEC dbo.sp_estindex @tableName = 'Marathon', @IndexColumns = 'racer_id, finish_time, is_disqualified', @Filter = 'WHERE racer_id IS NOT NULL', @FillFactor = 90;

*/

DECLARE @Sql NVARCHAR(MAX) = N''
    ,@QualifiedTable NVARCHAR(257)
    ,@IndexName SYSNAME = CONCAT('sp_estindex_hypothetical_idx_', DATEDIFF(SECOND,'1970-01-01 00:08:46', GETUTCDATE()))
    ,@DropIndexSql NVARCHAR(MAX)
    ,@Msg NVARCHAR(MAX) = N''
    ,@IndexType SYSNAME = 'NONCLUSTERED'
    ,@IsHeap BIT
    ,@IsClusterUnique BIT
    ,@ObjectID INT
    ,@IndexID INT
    ,@ParmDefinition NVARCHAR(MAX) = N''
    ,@NumRows BIGINT
    ,@UseDatabase NVARCHAR(200)
    ,@UniqueSql VARCHAR(10)
    ,@IncludeSql VARCHAR(2048)
    ,@PageSize BIGINT = 8192
    ,@FreeBytesPerPage BIGINT = 8096;

BEGIN TRY
    -- Find Version
	IF (@SqlMajorVersion = 0)
		BEGIN;
			SET @SqlMajorVersion = CAST(SERVERPROPERTY('ProductMajorVersion') AS TINYINT);
		END;

    /* Validate Version */
	IF (@SqlMajorVersion < 11)
		BEGIN;
			SET @Msg = 'SQL Server versions below 2012 are not supported, sorry!';
			RAISERROR(@Msg, 16, 1);
		END;

    /* Validate Fill Factor */
    IF (@FillFactor > 100 OR @FillFactor < 1)
        BEGIN;
            SET @Msg = 'Fill factor must be between 1 and 100.';
            THROW 51000, @Msg, 1;
        END;

    /* Validate Varchar Fill Percent */
    IF (@VarcharFillPercent > 100 OR @VarcharFillPercent < 1)
        BEGIN;
            SET @Msg = 'Varchar fill percent must be between 1 and 100.';
            THROW 51000, @Msg, 1;
        END;

    /* Validate Filter */
    IF (@Filter <> '' AND LEFT(@Filter, 5) <> 'WHERE')
        BEGIN;
            SET @Msg = 'Filter must start with ''WHERE''.';
            THROW 51000, @Msg, 1;
        END;

    /* Validate Database */
    IF (@DatabaseName IS NULL)
        BEGIN;
            SET @DatabaseName = DB_NAME();
            IF (@Verbose = 1)
                BEGIN;
                    SET @Msg = 'No database provided, assuming current database.';
                    RAISERROR(@Msg, 10, 1) WITH NOWAIT;
                END;
        END;
    ELSE IF (DB_ID(@DatabaseName) IS NULL)
        BEGIN;
            SET @DatabaseName = DB_NAME();
            SET @Msg = 'Database does not exist.';
            RAISERROR(@Msg, 16, 1);
        END;

    /* Validate Schema */
    IF (@SchemaName IS NULL)
        BEGIN;
            SET @SchemaName = 'dbo';
            IF (@Verbose = 1)
                BEGIN;
                    SET @Msg = 'No schema provided, assuming dbo.';
                    RAISERROR(@Msg, 10, 1) WITH NOWAIT;
                END;
        END;

    -- Set variables with validated params
    SET @QualifiedTable = CONCAT(QUOTENAME(@SchemaName), '.', QUOTENAME(@TableName));
    SET @UseDatabase = N'USE ' + QUOTENAME(@DatabaseName) + '; ';
    IF (@IsUnique = 1)
        BEGIN;
            SET @UniqueSql = ' UNIQUE ';
        END;
    IF (@IncludeColumns IS NOT NULL)
        BEGIN;
            SET @IncludeSql = CONCAT(' INCLUDE(', @IncludeColumns, ') ');
        END;

    -- Find object id
    SET @Sql = CONCAT(@UseDatabase,
        N'SELECT @ObjectID = [object_id]
        FROM [sys].[all_objects]
        WHERE [object_id] = OBJECT_ID(@QualifiedTable)');
	SET @ParmDefinition = N'@QualifiedTable NVARCHAR(257)
						,@ObjectID INT OUTPUT';
    EXEC sp_executesql @Sql
    ,@ParmDefinition
    ,@QualifiedTable
    ,@ObjectID OUTPUT;

    -- Determine Heap or Clustered
    SET @Sql = CONCAT(@UseDatabase,
        N'SELECT @IsHeap = CASE [type] WHEN 0 THEN 1 ELSE 0 END
            ,@IsClusterUnique = [is_unique]
         FROM [sys].[indexes]
         WHERE [object_id] = OBJECT_ID(@QualifiedTable)
         AND [type] IN (1, 0)');
	SET @ParmDefinition = N'@QualifiedTable NVARCHAR(257), @IsHeap BIT OUTPUT, @IsClusterUnique BIT OUTPUT';
	EXEC sp_executesql @Sql
		,@ParmDefinition
		,@QualifiedTable
		,@IsHeap OUTPUT
        ,@IsClusterUnique OUTPUT;

    -- Safety check for leftover index from previous run
    SET @DropIndexSql = CONCAT(@UseDatabase,
    N'IF EXISTS (SELECT 1 FROM [sys].[indexes] WHERE [object_id] = OBJECT_ID(''',@QualifiedTable,''') AND [name] = ''',@IndexName,''')
        DROP INDEX ', QUOTENAME(@IndexName), ' ON ', @QualifiedTable);
    EXEC sp_executesql @DropIndexSql;

    -- Fetch missing index stats before creation
    IF OBJECT_ID('tempdb..##TempMissingIndex') IS NOT NULL
        BEGIN;
            DROP TABLE ##TempMissingIndex;
        END;

    SET @Sql = CONCAT(@UseDatabase,
    N'SELECT [id].[statement]
        ,[id].[equality_columns]
        ,[id].[inequality_columns]
        ,[id].[included_columns]
        ,[gs].[unique_compiles]
        ,[gs].[user_seeks]
        ,[gs].[user_scans]
        ,[gs].[avg_total_user_cost] -- Average cost of the user queries that could be reduced
        ,[gs].[avg_user_impact]  -- %
    INTO ##TempMissingIndex
    FROM [sys].[dm_db_missing_index_group_stats] [gs]
    INNER JOIN [sys].[dm_db_missing_index_groups] [ig] ON [gs].[group_handle] = [ig].[index_group_handle]
    INNER JOIN [sys].[dm_db_missing_index_details] [id] ON [ig].[index_handle] = [id].[index_handle]
    WHERE [id].[database_id] = DB_ID()
        AND [id].[object_id] = @ObjectID
    OPTION (RECOMPILE);');
    SET @ParmDefinition = N'@ObjectID INT';
	EXEC sp_executesql @Sql
		,@ParmDefinition
        ,@ObjectID;

    -- Create the hypothetical index
    SET @Sql = CONCAT(@UseDatabase, 'CREATE ', @UniqueSql, @IndexType, ' INDEX ', QUOTENAME(@IndexName), ' ON ', @QualifiedTable, ' (', @IndexColumns, ') ',@IncludeSql, @Filter, ' WITH (STATISTICS_ONLY = -1)');
    EXEC sp_executesql @Sql;

    /*******************/
    /* Get index stats */
    /*******************/
    -- Use DBCC to avoid various inconsistencies
    -- in equivalent DMVs between 2012-2016
    SET @Sql = CONCAT(@UseDatabase, 'DBCC SHOW_STATISTICS ("', @QualifiedTable,'", ', QUOTENAME(@IndexName), ')');
    EXEC sp_executesql @Sql;

    /***************************/
    /* Get missing index stats */
    /***************************/
    DECLARE @QuotedKeyColumns NVARCHAR(2048)
        ,@QuotedInclColumns NVARCHAR(2048);

    --Get index columns in same format as dmv table
    SET @Sql = CONCAT(@UseDatabase,
    N'SELECT    @QuotedKeyColumns = CASE WHEN [ic].[is_included_column] = 0
									THEN CONCAT(COALESCE(@QuotedKeyColumns COLLATE DATABASE_DEFAULT + '', '', ''''), QUOTENAME([ac].[name]))
									ELSE @QuotedKeyColumns
                                    END,
	            @QuotedInclColumns = CASE WHEN [ic].[is_included_column] = 1
									THEN CONCAT(COALESCE(@QuotedInclColumns COLLATE DATABASE_DEFAULT + '', '', ''''), QUOTENAME([ac].[name]))
									ELSE @QuotedInclColumns
                                    END
    FROM [sys].[indexes] AS [i]
        INNER JOIN [sys].[index_columns] AS [ic] ON [i].[index_id] = [ic].[index_id]
            AND [ic].object_id = [i].object_id
        INNER JOIN [sys].[all_columns] AS [ac] ON [ac].[object_id] = [ic].[object_id]
            AND [ac].[column_id] = [ic].[column_id]
    WHERE [i].[name] = @IndexName
        AND [i].[object_id] = @ObjectID
        AND [i].[is_hypothetical] = 1;');
    SET @ParmDefinition = N'@IndexName SYSNAME, @ObjectID INT, @QuotedKeyColumns NVARCHAR(2048) OUTPUT, @QuotedInclColumns NVARCHAR(2048) OUTPUT';
	EXEC sp_executesql @Sql
		,@ParmDefinition
		,@IndexName
        ,@ObjectID
        ,@QuotedKeyColumns OUTPUT
        ,@QuotedInclColumns OUTPUT;

    -- Search missing index dmv for a match
    SELECT 'Missing index stats' AS [description]
        ,[statement]
        ,[equality_columns]
        ,[inequality_columns]
        ,[included_columns]
        ,[unique_compiles]
        ,[user_seeks]
        ,[user_scans]
        ,[avg_total_user_cost]
        ,[avg_user_impact]
    FROM ##TempMissingIndex
    WHERE COALESCE([equality_columns] + ', ', '') + [inequality_columns] = @QuotedKeyColumns
        AND ([included_columns] = @QuotedInclColumns OR [included_columns] IS NULL);

    IF (SELECT COUNT(1) FROM ##TempMissingIndex) = 0 AND (@Verbose = 1)
        BEGIN;
            SET @Msg = 'No matching missing index statistics found.';
            RAISERROR(@Msg, 10, 1) WITH NOWAIT;
        END;

    DROP TABLE ##TempMissingIndex;

    /************************************************/
    /* Estimate index size - does NOT consider:     */
    /* Partitioning, allocation pages, LOB values,  */
    /* compression, or sparse columns               */
    /************************************************/
    IF (@IndexType = 'NONCLUSTERED') -- http://dba-multitool.org/est-nonclustered-index-size
    BEGIN;
        DECLARE @NumVariableKeyCols INT = 0
            ,@MaxVarKeySize BIGINT = 0
            ,@NumFixedKeyCols INT = 0
            ,@FixedKeySize BIGINT = 0
            ,@NumKeyCols INT = 0
            ,@NullCols INT = 0
            ,@IndexNullBitmap BIGINT = 0
            ,@VariableKeySize BIGINT = 0
            ,@VariableKeyFillModifier DECIMAL(3,2) = (@VarcharFillPercent / 100)
            ,@TotalFixedKeySize BIGINT = 0
            ,@IndexRowSize BIGINT = 0
            ,@IndexRowsPerPage BIGINT = 0
            ,@ClusterNumVarKeyCols INT = 0
            ,@MaxClusterVarKeySize BIGINT = 0
            ,@ClusterNumFixedKeyCols INT = 0
            ,@MaxClusterFixedKeySize BIGINT = 0
            ,@ClusterNullCols INT = 0;

        /**************************/
        /* 1. Calculate variables */
        /**************************/
        -- Row count
        SET @Sql = CONCAT(@UseDatabase,
        N'SELECT @NumRows = [sp].[rows] -- Accounts for index filter if in use
        FROM [sys].[objects] AS [o]
            INNER JOIN [sys].[stats] AS [stat] ON [stat].[object_id] = [o].[object_id]
            CROSS APPLY [sys].[dm_db_stats_properties]([stat].[object_id], [stat].[stats_id]) AS [sp]
        WHERE [o].[object_id] = @ObjectID
            AND [stat].[name] = @IndexName;');
        SET @ParmDefinition = N'@ObjectID INT, @IndexName SYSNAME, @NumRows BIGINT OUTPUT';
	    EXEC sp_executesql @Sql
		,@ParmDefinition
		,@ObjectID
        ,@IndexName
        ,@NumRows OUTPUT;

        IF (@Verbose = 1)
            BEGIN
                SET @Msg = CONCAT('NumRows: ', @NumRows);
                RAISERROR(@Msg, 10, 1) WITH NOWAIT;
            END;

        --Key types and sizes
        SET @Sql = CONCAT(@UseDatabase,
        N'SELECT @NumVariableKeyCols = ISNULL(SUM(CASE
                    WHEN TYPE_NAME([ac].[user_type_id]) IN(''varchar'', ''nvarchar'', ''text'', ''ntext'', ''image'', ''varbinary'', ''xml'')
                    THEN 1
                    ELSE 0
                END), 0),
            @MaxVarKeySize = ISNULL(SUM(CASE
                    WHEN TYPE_NAME([ac].[user_type_id]) IN(''varchar'', ''nvarchar'', ''text'', ''ntext'', ''image'', ''varbinary'', ''xml'')
                    THEN CASE [ac].[max_length]
                                WHEN -1
                                THEN(4000 + 2) -- use same estimation as the query engine for max lenths
                                ELSE COL_LENGTH(OBJECT_NAME([i].object_id), [ac].[name])
                            END
                    ELSE 0
                END), 0),
            @NumFixedKeyCols = ISNULL(SUM(CASE
                    WHEN TYPE_NAME([ac].[user_type_id]) NOT IN(''varchar'', ''nvarchar'', ''text'', ''ntext'', ''image'', ''varbinary'', ''xml'')
                    THEN 1
                    ELSE 0
                END), 0),
            @FixedKeySize = ISNULL(SUM(CASE
                    WHEN TYPE_NAME([ac].[user_type_id]) NOT IN(''varchar'', ''nvarchar'', ''text'', ''ntext'', ''image'', ''varbinary'', ''xml'')
                    THEN COL_LENGTH(OBJECT_NAME([i].object_id), [ac].[name])
                    ELSE 0
                END), 0),
            @NullCols = ISNULL(SUM(CAST([ac].[is_nullable] AS TINYINT)),0)
        FROM [sys].[indexes] AS [i]
            INNER JOIN [sys].[index_columns] AS [ic] ON [i].[index_id] = [ic].[index_id]
                AND [ic].object_id = [i].object_id
            INNER JOIN [sys].[all_columns] AS [ac] ON [ac].object_id = [ic].object_id
                AND [ac].[column_id] = [ic].[column_id]
        WHERE [i].[name] = @IndexName
            AND [i].[object_id] = @ObjectID
            AND [i].[is_hypothetical] = 1
            AND [ic].[is_included_column] = 0');
        SET @ParmDefinition = N'@IndexName SYSNAME, @ObjectID INT, @NumVariableKeyCols INT OUTPUT,
            @MaxVarKeySize BIGINT OUTPUT, @NumFixedKeyCols INT OUTPUT, @FixedKeySize BIGINT OUTPUT,
            @NullCols INT OUTPUT';
	    EXEC sp_executesql @Sql
		,@ParmDefinition
		,@IndexName
        ,@ObjectID
        ,@NumVariableKeyCols OUTPUT
        ,@MaxVarKeySize OUTPUT
        ,@NumFixedKeyCols OUTPUT
        ,@FixedKeySize OUTPUT
        ,@NullCols OUTPUT;

        SET @NumKeyCols = @NumVariableKeyCols + @NumFixedKeyCols;

        IF (@Verbose = 1)
            BEGIN
                SET @Msg = CONCAT('NumVariableKeyCols: ', @NumVariableKeyCols);
                RAISERROR(@Msg, 10, 1) WITH NOWAIT;
                SET @Msg = CONCAT('MaxVarKeySize: ', @MaxVarKeySize);
                RAISERROR(@Msg, 10, 1) WITH NOWAIT;
                SET @Msg = CONCAT('NumFixedKeyCols: ', @NumFixedKeyCols);
                RAISERROR(@Msg, 10, 1) WITH NOWAIT;
                SET @Msg = CONCAT('FixedKeySize: ', @FixedKeySize);
                RAISERROR(@Msg, 10, 1) WITH NOWAIT;
                SET @Msg = CONCAT('NullCols: ', @NullCols);
                RAISERROR(@Msg, 10, 1) WITH NOWAIT;
                SET @Msg = CONCAT('NumKeyCols: ', @NumKeyCols);
                RAISERROR(@Msg, 10, 1) WITH NOWAIT;
            END;

        -- Account for data row locator for non-unique
        IF (@IsHeap = 1 AND @IsUnique = 0)
            BEGIN;
                SET @NumKeyCols = @NumKeyCols + 1;
                SET @NumVariableKeyCols = @NumVariableKeyCols + 1;
                SET @MaxVarKeySize = @MaxVarKeySize + 8; --heap RID
            END;
        ELSE IF (@IsHeap = 0 AND @IsUnique = 0)
            BEGIN;
                --Clustered keys and sizes not included in the new index
                SET @Sql = CONCAT(@UseDatabase,
                N'WITH NewIndexCol AS (
                    SELECT [ac].[name]
                    FROM [sys].[indexes] AS [i]
                        INNER JOIN [sys].[index_columns] AS [ic] ON [i].[index_id] = [ic].[index_id]
                            AND [ic].object_id = [i].object_id
                        INNER JOIN [sys].[all_columns] AS [ac] ON [ac].object_id = [ic].object_id
                            AND [ac].[column_id] = [ic].[column_id]
                    WHERE [i].[name] = @IndexName
                        AND [i].[object_id] = @ObjectID
                        AND [i].[is_hypothetical] = 1
                        AND [ic].[is_included_column] = 0
                )
                SELECT @ClusterNumVarKeyCols = ISNULL(SUM(CASE
                            WHEN TYPE_NAME([ac].[user_type_id]) IN(''varchar'', ''nvarchar'', ''text'', ''ntext'', ''image'', ''varbinary'', ''xml'')
                            THEN 1
                            ELSE 0
                        END), 0),
                    @MaxClusterVarKeySize = ISNULL(SUM(CASE
                            WHEN TYPE_NAME([ac].[user_type_id]) IN(''varchar'', ''nvarchar'', ''text'', ''ntext'', ''image'', ''varbinary'', ''xml'')
                            THEN CASE [ac].[max_length]
                                        WHEN -1
                                        THEN(4000 + 2) -- use same estimation as the query engine for max lenths
                                        ELSE COL_LENGTH(OBJECT_NAME([i].object_id), [ac].[name])
                                    END
                            ELSE 0
                        END), 0),
                    @ClusterNumFixedKeyCols = ISNULL(SUM(CASE
                            WHEN TYPE_NAME([ac].[user_type_id]) NOT IN(''varchar'', ''nvarchar'', ''text'', ''ntext'', ''image'', ''varbinary'', ''xml'')
                            THEN 1
                            ELSE 0
                        END), 0),
                    @MaxClusterFixedKeySize = ISNULL(SUM(CASE
                            WHEN TYPE_NAME([ac].[user_type_id]) NOT IN(''varchar'', ''nvarchar'', ''text'', ''ntext'', ''image'', ''varbinary'', ''xml'')
                            THEN COL_LENGTH(OBJECT_NAME([i].object_id), [ac].[name])
                            ELSE 0
                        END), 0),
                    @ClusterNullCols = ISNULL(SUM(CAST([ac].[is_nullable] AS TINYINT)),0)
                FROM [sys].[indexes] AS [i]
                    INNER JOIN [sys].[index_columns] AS [ic] ON [i].[index_id] = [ic].[index_id]
                        AND [ic].object_id = [i].object_id
                    INNER JOIN [sys].[all_columns] AS [ac] ON [ac].object_id = [ic].object_id
                        AND [ac].[column_id] = [ic].[column_id]
                WHERE [i].[type] = 1 --Clustered
                    AND [i].[object_id] = @ObjectID
                    AND [ac].[name] NOT IN (SELECT [name] FROM [NewIndexCol]);');
                SET @ParmDefinition = N'@IndexName SYSNAME, @ObjectID INT, @ClusterNumVarKeyCols INT OUTPUT,
                    @MaxClusterVarKeySize BIGINT OUTPUT, @ClusterNumFixedKeyCols INT OUTPUT,
                    @MaxClusterFixedKeySize BIGINT OUTPUT, @ClusterNullCols INT OUTPUT';
                EXEC sp_executesql @Sql
                ,@ParmDefinition
                ,@IndexName
                ,@ObjectID
                ,@ClusterNumVarKeyCols OUTPUT
                ,@MaxClusterVarKeySize OUTPUT
                ,@ClusterNumFixedKeyCols OUTPUT
                ,@MaxClusterFixedKeySize OUTPUT
                ,@ClusterNullCols OUTPUT;

                IF (@Verbose = 1)
                    BEGIN
                        SET @Msg = CONCAT('ClusterNumVarKeyCols: ', @ClusterNumVarKeyCols);
                        RAISERROR(@Msg, 10, 1) WITH NOWAIT;
                        SET @Msg = CONCAT('ClusterNumFixedKeyCols: ', @ClusterNumFixedKeyCols);
                        RAISERROR(@Msg, 10, 1) WITH NOWAIT;
                        SET @Msg = CONCAT('MaxClusterVarKeySize: ', @MaxClusterVarKeySize);
                        RAISERROR(@Msg, 10, 1) WITH NOWAIT;
                        SET @Msg = CONCAT('MaxClusterFixedKeySize: ', @MaxClusterFixedKeySize);
                        RAISERROR(@Msg, 10, 1) WITH NOWAIT;
                        SET @Msg = CONCAT('ClusterNullCols: ', @ClusterNullCols);
                        RAISERROR(@Msg, 10, 1) WITH NOWAIT;
                    END;

                -- Add counts from clustered index cols
                SET @NumKeyCols = @NumKeyCols + (@ClusterNumVarKeyCols + @ClusterNumFixedKeyCols);
                SET @FixedKeySize = @FixedKeySize + @MaxClusterFixedKeySize;
                SET @NumVariableKeyCols = @NumVariableKeyCols + @ClusterNumVarKeyCols;
                SET @MaxVarKeySize = @MaxVarKeySize + @MaxClusterVarKeySize;
                SET @NullCols = @NullCols + @ClusterNullCols;

                IF (@IsClusterUnique = 0)
                    BEGIN;
                        SET @MaxVarKeySize = @MaxVarKeySize + 4;
                        SET @NumVariableKeyCols = @NumVariableKeyCols + 1;
                        SET @NumKeyCols = @NumKeyCols + 1;
                    END;
            END;

        IF (@Verbose = 1)
            BEGIN
                SET @Msg = CONCAT('FixedKeySize: ', @FixedKeySize);
                RAISERROR(@Msg, 10, 1) WITH NOWAIT;
                SET @Msg = CONCAT('NumVariableKeyCols: ', @NumVariableKeyCols);
                RAISERROR(@Msg, 10, 1) WITH NOWAIT;
                SET @Msg = CONCAT('NumKeyCols: ', @NumKeyCols);
                RAISERROR(@Msg, 10, 1) WITH NOWAIT;
                SET @Msg = CONCAT('MaxVarKeySize: ', @MaxVarKeySize);
                RAISERROR(@Msg, 10, 1) WITH NOWAIT;
                SET @Msg = CONCAT('NullCols: ', @NullCols);
                RAISERROR(@Msg, 10, 1) WITH NOWAIT;
            END;

        -- Account for index null bitmap
        IF (@NullCols > 0)
            BEGIN;
                SET @IndexNullBitmap = 2 + ((@NullCols + 7) / 8);
            END;

        -- Calculate variable length data size
        -- Assumes each col is 100% full unless
        -- otherwise specified
        IF (@NumVariableKeyCols > 0)
            BEGIN;
                --The bytes added to @MaxVarKeySize are for tracking each variable column.
                SET @VariableKeySize = 2 + (@NumVariableKeyCols * 2) + (@MaxVarKeySize * @VariableKeyFillModifier);
            END;

        -- Calculate index row size
        -- + 1 (for row header overhead of an index row) + 6 (for the child page ID pointer)
        SET @IndexRowSize = @FixedKeySize + @VariableKeySize + @IndexNullBitmap + 1 + 6;
        IF (@Verbose = 1)
            BEGIN
                SET @Msg = CONCAT('IndexRowSize: ', @IndexRowSize);
                RAISERROR(@Msg, 10, 1) WITH NOWAIT;
            END;

        -- Calculate number of index rows / page
        -- + 2 for the row's entry in the page's slot array.
        SET @IndexRowsPerPage = FLOOR(@FreeBytesPerPage / (@IndexRowSize + 2));

        IF (@Verbose = 1)
            BEGIN
                SET @Msg = CONCAT('IndexRowsPerPage: ', @IndexRowsPerPage);
                RAISERROR(@Msg, 10, 1) WITH NOWAIT;
            END;

        /****************************************************************************/
        /* 2. Calculate the Space Used to Store Index Information in the Leaf Level */
        /****************************************************************************/
        -- Specify the number of fixed-length and variable-length columns at the leaf level
        -- and calculate the space that is required for their storage
        DECLARE @NumLeafCols INT = @NumKeyCols
            ,@FixedLeafSize BIGINT = @FixedKeySize
            ,@NumVariableLeafCols INT = @NumVariableKeyCols
            ,@MaxVarLeafSize BIGINT = @MaxVarKeySize
            ,@LeafNullBitmap BIGINT = 0
            ,@VariableLeafSize BIGINT = 0
            ,@LeafRowSize BIGINT = 0
            ,@LeafRowsPerPage BIGINT = 0
            ,@FreeRowsPerPage BIGINT = 0
            ,@NumLeafPages BIGINT = 0
            ,@LeafSpaceUsed BIGINT = 0;

        IF (@IncludeColumns IS NOT NULL)
            BEGIN;
                DECLARE @NumVariableInclCols INT = 0
                    ,@MaxVarInclSize BIGINT = 0
                    ,@NumFixedInclCols INT = 0
                    ,@FixedInclSize BIGINT = 0;

                --Incl types and sizes
                SET @Sql = CONCAT(@UseDatabase,
                N'SELECT @NumVariableInclCols = ISNULL(SUM(CASE
                            WHEN TYPE_NAME([ac].[user_type_id]) IN(''varchar'', ''nvarchar'', ''text'', ''ntext'', ''image'', ''varbinary'', ''xml'')
                            THEN 1
                            ELSE 0
                        END), 0),
                    @MaxVarInclSize = ISNULL(SUM(CASE
                            WHEN TYPE_NAME([ac].[user_type_id]) IN(''varchar'', ''nvarchar'', ''text'', ''ntext'', ''image'', ''varbinary'', ''xml'')
                            THEN CASE [ac].[max_length]
                                        WHEN -1
                                        THEN (4000 + 2) -- use same estimation as the query engine for max lenths
                                        ELSE COL_LENGTH(OBJECT_NAME([i].object_id), [ac].[name])
                                    END
                            ELSE 0
                        END), 0),
                    @NumFixedInclCols = ISNULL(SUM(CASE
                            WHEN TYPE_NAME([ac].[user_type_id]) NOT IN(''varchar'', ''nvarchar'', ''text'', ''ntext'', ''image'', ''varbinary'', ''xml'')
                            THEN 1
                            ELSE 0
                        END), 0),
                    @FixedInclSize = ISNULL(SUM(CASE
                            WHEN TYPE_NAME([ac].[user_type_id]) NOT IN(''varchar'', ''nvarchar'', ''text'', ''ntext'', ''image'', ''varbinary'', ''xml'')
                            THEN COL_LENGTH(OBJECT_NAME([i].object_id), [ac].[name])
                            ELSE 0
                        END), 0)
                FROM [sys].[indexes] AS [i]
                    INNER JOIN [sys].[index_columns] AS [ic] ON [i].[index_id] = [ic].[index_id]
                        AND [ic].object_id = [i].object_id
                    INNER JOIN [sys].[all_columns] AS [ac] ON [ac].object_id = [ic].object_id
                        AND [ac].[column_id] = [ic].[column_id]
                WHERE [i].[name] = @IndexName
                    AND [i].[object_id] = @ObjectID
                    AND [i].[is_hypothetical] = 1
                    AND [ic].[is_included_column] = 1;');
                SET @ParmDefinition = N'@IndexName SYSNAME, @ObjectID INT, @NumVariableInclCols INT OUTPUT,
                    @MaxVarInclSize BIGINT OUTPUT, @NumFixedInclCols INT OUTPUT, @FixedInclSize BIGINT OUTPUT';
                EXEC sp_executesql @Sql
                ,@ParmDefinition
                ,@IndexName
                ,@ObjectID
                ,@NumVariableInclCols OUTPUT
                ,@MaxVarInclSize OUTPUT
                ,@NumFixedInclCols OUTPUT
                ,@FixedInclSize OUTPUT;

                -- Add included columns to rolling totals
                SET @NumLeafCols = @NumLeafCols + (@NumVariableInclCols + @NumFixedInclCols);
                SET @FixedLeafSize = @FixedLeafSize + @FixedInclSize;
                SET @NumVariableLeafCols = @NumVariableLeafCols + @NumVariableInclCols;
                SET @MaxVarLeafSize = @MaxVarLeafSize + @MaxVarInclSize;
            END;

        -- Account for data row locator for unique indexes
        -- If non-unique, already accounted for above
        IF (@IsUnique = 1)
            BEGIN;
                IF (@IsHeap = 1)
                    BEGIN;
                        SET @NumLeafCols = @NumLeafCols + 1;
                        SET @NumVariableLeafCols = @NumVariableLeafCols + 1;
                        SET @MaxVarLeafSize = @MaxVarLeafSize + 8; -- the data row locator is the heap RID (size 8 bytes).
                    END;
                ELSE -- Clustered
                    BEGIN;
                        SET @NumLeafCols = @NumLeafCols + (@ClusterNumVarKeyCols + @ClusterNumFixedKeyCols);
                        SET @FixedLeafSize = @FixedLeafSize + @ClusterNumFixedKeyCols;
                        SET @NumVariableLeafCols = @NumVariableLeafCols + @ClusterNumVarKeyCols;
                        SET @MaxVarLeafSize = @MaxVarLeafSize + @MaxClusterVarKeySize;

                        IF (@IsClusterUnique = 0)
                            BEGIN;
                                SET @NumLeafCols = @NumLeafCols + 1;
                                SET @NumVariableLeafCols = @NumVariableLeafCols + 1;
                                SET @MaxVarLeafSize = @MaxVarLeafSize + 4;
                            END;
                    END;
            END;

        IF (@Verbose = 1)
            BEGIN
                SET @Msg = CONCAT('NumLeafCols: ', @NumLeafCols);
                RAISERROR(@Msg, 10, 1) WITH NOWAIT;
                SET @Msg = CONCAT('FixedLeafSize: ', @FixedLeafSize);
                RAISERROR(@Msg, 10, 1) WITH NOWAIT;
                SET @Msg = CONCAT('NumVariableLeafCols: ', @NumVariableLeafCols);
                RAISERROR(@Msg, 10, 1) WITH NOWAIT;
                SET @Msg = CONCAT('MaxVarLeafSize: ', @MaxVarLeafSize);
                RAISERROR(@Msg, 10, 1) WITH NOWAIT;
            END;

        -- Account for index null bitmap
        SET @LeafNullBitmap = 2 + ((@NumLeafCols + 7) / 8);

        IF (@Verbose = 1)
            BEGIN
                SET @Msg = CONCAT('LeafNullBitmap: ', @LeafNullBitmap);
                RAISERROR(@Msg, 10, 1) WITH NOWAIT;
            END;

        -- Calculate variable length data size
        -- Assumes each col is 100% full
        IF (@NumVariableLeafCols > 0)
            BEGIN;
                SET @VariableLeafSize = 2 + (@NumVariableLeafCols * 2) + @MaxVarLeafSize;
            END;

        IF (@Verbose = 1)
            BEGIN
                SET @Msg = CONCAT('VariableLeafSize: ', @VariableLeafSize);
                RAISERROR(@Msg, 10, 1) WITH NOWAIT;
            END;

        -- Calculate index row size
        SET @LeafRowSize = @FixedLeafSize + @VariableLeafSize + @LeafNullBitmap + 1; -- +1 for row header overhead of an index row)

        IF (@Verbose = 1)
            BEGIN
                SET @Msg = CONCAT('LeafRowSize: ', @LeafRowSize);
                RAISERROR(@Msg, 10, 1) WITH NOWAIT;
            END;

        -- Calculate number of index rows / page
        SET @LeafRowsPerPage = FLOOR(@FreeBytesPerPage / (@LeafRowSize + 2)); -- + 2 for the row's entry in the page's slot array.

        IF (@Verbose = 1)
            BEGIN
                SET @Msg = CONCAT('LeafRowsPerPage: ', @LeafRowsPerPage);
                RAISERROR(@Msg, 10, 1) WITH NOWAIT;
            END;

        -- Calculate free rows / page
        SET @FreeRowsPerPage = @FreeBytesPerPage * (( 100 - @FillFactor) / 100) / (@LeafRowSize + 2); -- + 2 for the row's entry in the page's slot array.

        IF (@Verbose = 1)
            BEGIN
                SET @Msg = CONCAT('FreeRowsPerPage: ', @FreeRowsPerPage);
                RAISERROR(@Msg, 10, 1) WITH NOWAIT;
            END;

        -- Calculate pages for all rows
        SET @NumLeafPages = CEILING(@NumRows / (@LeafRowsPerPage - @FreeRowsPerPage));

        IF (@Verbose = 1)
            BEGIN
                SET @Msg = CONCAT('NumLeafPages: ', @NumLeafPages);
                RAISERROR(@Msg, 10, 1) WITH NOWAIT;
            END;

        -- Calculate size of index at leaf level
        SET @LeafSpaceUsed = @PageSize * @NumLeafPages;

        /*********************************************************************************/
        /* 3. Calculate the Space Used to Store Index Information in the Non-leaf Levels */
        /*********************************************************************************/
        DECLARE @NonLeafLevels BIGINT = 0,
            @NumIndexPages BIGINT = 0,
            @IndexSpaceUsed BIGINT = 0;

        -- Calculate the number of non-leaf levels in the index
        SET @NonLeafLevels = CEILING(1 + LOG(@IndexRowsPerPage) * (@NumLeafPages / @IndexRowsPerPage));

        IF (@Verbose = 1)
            BEGIN
                SET @Msg = CONCAT('NonLeafLevels: ', @NonLeafLevels);
                RAISERROR(@Msg, 10, 1) WITH NOWAIT;
            END;

        --Formula: IndexPages = Summation (Num_Leaf_Pages/Index_Rows_Per_Page^Level)where 1 <= Level <= Levels
        WHILE (@NonLeafLevels > 1)
            BEGIN
                DECLARE @TempIndexPages FLOAT(30);

                -- TempIndexPages may be exceedingly small, so catch any arith overflows and call it 0
                BEGIN TRY;
                    SET @TempIndexPages = @NumLeafPages / POWER(@IndexRowsPerPage, @NonLeafLevels);
                    SET @NumIndexPages = @NumIndexPages + @TempIndexPages;
                    SET @NonLeafLevels = @NonLeafLevels - 1;
                END TRY
                BEGIN CATCH;
                    SET @NonLeafLevels = @NonLeafLevels - 1;
                END CATCH;
            END;

        -- Calculate size of the index
        SET @IndexSpaceUsed = @PageSize * @NumIndexPages;

        /**************************************/
        /* 4. Total index and leaf space used */
        /**************************************/
        DECLARE @Total BIGINT = 0;

        SET @Total = @LeafSpaceUsed + @IndexSpaceUsed;

        SELECT @Total/1024 AS [Est. KB]
            ,CAST(ROUND(@Total/1024.0/1024.0,2,1) AS DECIMAL(30,2)) AS [Est. MB]
            ,CAST(ROUND(@Total/1024.0/1024.0/1024.0,2,1) AS DECIMAL(30,4)) AS [Est. GB];
    END;

    --Cleanup
    EXEC sp_executesql @DropIndexSql;

END TRY
BEGIN CATCH;
    BEGIN;
        DECLARE @ErrorNumber INT = ERROR_NUMBER();
        DECLARE @ErrorLine INT = ERROR_LINE();
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();

        EXEC sp_executesql @DropIndexSql;

        SET @ErrorMessage = CONCAT(QUOTENAME(OBJECT_NAME(@@PROCID)), ': ', @ErrorMessage);
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState) WITH NOWAIT;
    END;
END CATCH;

END;
GO

EXEC sys.sp_addextendedproperty @name=N'@DatabaseName', @value=N'Target database of the index''s table.' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'sp_estindex';
GO

EXEC sys.sp_addextendedproperty @name=N'@FillFactor', @value=N'Optional fill factor for the index. Default is 100.' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'sp_estindex';
GO

EXEC sys.sp_addextendedproperty @name=N'@Filter', @value=N'Optional filter for the index.' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'sp_estindex';
GO

EXEC sys.sp_addextendedproperty @name=N'@IncludeColumns', @value=N'Optional comma separated list of include columns.' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'sp_estindex';
GO

EXEC sys.sp_addextendedproperty @name=N'@IndexColumns', @value=N'Comma separated list of key columns.' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'sp_estindex';
GO

EXEC sys.sp_addextendedproperty @name=N'@IsUnique', @value=N'Whether or not the index is UNIQUE. Default is 0.' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'sp_estindex';
GO

EXEC sys.sp_addextendedproperty @name=N'@SchemaName', @value=N'Target schema of the index''s table. Default is ''dbo''.' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'sp_estindex';
GO

EXEC sys.sp_addextendedproperty @name=N'@SqlMajorVersion', @value=N'For unit testing only.' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'sp_estindex';
GO

EXEC sys.sp_addextendedproperty @name=N'@TableName', @value=N'Target table for the index. Default is current database.' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'sp_estindex';
GO

EXEC sys.sp_addextendedproperty @name=N'Description', @value=N'Estimate a new index''s size and statistics.' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'sp_estindex';
GO

EXEC sys.sp_addextendedproperty @name=N'@VarcharFillPercent', @value=N'Optional estimated fill percent of data in variable length columns. Default is 100.' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'sp_estindex';
GO

EXEC sys.sp_addextendedproperty @name=N'@Verbose', @value=N'Show intermediate variables used in size calculations. Default is 0.' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'sp_estindex';
GO
SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

IF  EXISTS (SELECT * FROM sys.fn_listextendedproperty(N'Description' , N'SCHEMA',N'dbo', N'PROCEDURE',N'sp_helpme', NULL,NULL))
	BEGIN;
		EXEC sys.sp_dropextendedproperty @name=N'Description' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'sp_helpme';
	END
GO

IF  EXISTS (SELECT * FROM sys.fn_listextendedproperty(N'@SqlMinorVersion' , N'SCHEMA',N'dbo', N'PROCEDURE',N'sp_helpme', NULL,NULL))
	BEGIN;
		EXEC sys.sp_dropextendedproperty @name=N'@SqlMinorVersion' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'sp_helpme';
	END
GO

IF  EXISTS (SELECT * FROM sys.fn_listextendedproperty(N'@SqlMajorVersion' , N'SCHEMA',N'dbo', N'PROCEDURE',N'sp_helpme', NULL,NULL))
	BEGIN;
		EXEC sys.sp_dropextendedproperty @name=N'@SqlMajorVersion' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'sp_helpme';
	END
GO

IF  EXISTS (SELECT * FROM sys.fn_listextendedproperty(N'@ExtendedPropertyName' , N'SCHEMA',N'dbo', N'PROCEDURE',N'sp_helpme', NULL,NULL))
	BEGIN;
		EXEC sys.sp_dropextendedproperty @name=N'@ExtendedPropertyName' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'sp_helpme';
	END
GO

IF  EXISTS (SELECT * FROM sys.fn_listextendedproperty(N'@ObjectName' , N'SCHEMA',N'dbo', N'PROCEDURE',N'sp_helpme', NULL,NULL))
	BEGIN;
		EXEC sys.sp_dropextendedproperty @name=N'@ObjectName' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'sp_helpme';
	END
GO

/***************************/
/* Create stored procedure */
/***************************/
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_helpme]') AND [type] IN (N'P', N'PC'))
	BEGIN;
		EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[sp_helpme] AS';
	END
GO

ALTER PROCEDURE [dbo].[sp_helpme]
	@ObjectName SYSNAME = NULL
	,@ExtendedPropertyName SYSNAME = 'Description'
	/* Parameters defined here for testing only */
	,@SqlMajorVersion TINYINT = 0
	,@SqlMinorVersion SMALLINT = 0
AS

/*
sp_helpme - A drop-in modern alternative to sp_help.

Part of the DBA MultiTool http://dba-multitool.org

Version: 20230108

MIT License

Copyright (c) 2023 John McCall

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

	EXEC sp_helpme 'dbo.Sales';

*/

BEGIN
	SET NOCOUNT ON;

	DECLARE	@DbName	SYSNAME
		,@ObjShortName SYSNAME = N''
		,@No VARCHAR(5)	= 'no'
		,@Yes VARCHAR(5) = 'yes'
		,@None VARCHAR(5) = 'none'
		,@SysObj_Type CHAR(2)
		,@ObjID INT
		,@HasParam INT = 0
		,@HasDepen BIT = 0
		,@HasHidden BIT = 0
		,@HasMasked BIT = 0
		,@SQLString NVARCHAR(MAX) = N''
		,@Msg NVARCHAR(MAX) = N''
		,@ParmDefinition NVARCHAR(500);

	/* Find Version */
	IF (@SqlMajorVersion = 0)
		BEGIN;
			SET @SqlMajorVersion = CAST(SERVERPROPERTY('ProductMajorVersion') AS TINYINT);
		END;
	IF (@SqlMinorVersion = 0)
		BEGIN;
			SET @SqlMinorVersion = CAST(SERVERPROPERTY('ProductMinorVersion') AS TINYINT);
		END;

	/* Validate Version */
	IF (@SqlMajorVersion < 11)
		BEGIN;
			SET @Msg = 'SQL Server versions below 2012 are not supported, sorry!';
			RAISERROR(@Msg, 16, 1);
		END;

	/* Check for Hidden Columns feature */
	IF 1 = (SELECT COUNT(1) FROM sys.all_columns AS ac WHERE ac.name = 'is_hidden' AND OBJECT_NAME(ac.object_id) = 'all_columns')
		BEGIN
			SET @HasHidden = 1;
		END;

	/* Check for Masked Columns feature */
	IF 1 = (SELECT COUNT(1) FROM sys.all_columns AS ac WHERE ac.name = 'is_masked' AND OBJECT_NAME(ac.object_id) = 'all_columns')
		BEGIN
			SET @HasMasked = 1;
		END;

	-- If no @ObjectName given, give a little info about all objects.
	IF (@ObjectName IS NULL)
	BEGIN;
		SET @SQLString = N'SELECT
				[Name] = [o].[name],
				[Owner] = USER_NAME(OBJECTPROPERTY([object_id], ''ownerid'')),
				[Object_type] = LOWER(REPLACE([o].[type_desc], ''_'', '' '')),
				[Create_datetime] = [o].[create_date],
				[Modify_datetime] = [o].[modify_date],
				[ExtendedProperty] = [ep].[value]
			FROM [sys].[all_objects] [o]
				LEFT JOIN [sys].[extended_properties] [ep] ON [ep].[major_id] = [o].[object_id]
					and [ep].[name] = @ExtendedPropertyName
					AND [ep].[minor_id] = 0
					AND [ep].[class] = 1
			ORDER BY [Owner] ASC, [Object_type] DESC, [Name] ASC;';
		SET @ParmDefinition = N'@ExtendedPropertyName SYSNAME';

		EXEC sp_executesql @SQLString
			,@ParmDefinition
			,@ExtendedPropertyName;

		-- Display all user types
		SET @SQLString = N'SELECT
			[User_type]		= [name],
			[Storage_type]	= TYPE_NAME(system_type_id),
			[Length]		= max_length,
			[Prec]			= [precision],
			[Scale]			= [scale],
			[Nullable]		= CASE WHEN is_nullable = 1 THEN @Yes ELSE @No END,
			[Default_name]	= ISNULL(OBJECT_NAME(default_object_id), @None),
			[Rule_name]		= ISNULL(OBJECT_NAME(rule_object_id), @None),
			[Collation]		= collation_name
		FROM sys.types
		WHERE user_type_id > 256
		ORDER BY [name];';
		SET @ParmDefinition = N'@Yes VARCHAR(5), @No VARCHAR(5), @None VARCHAR(5)';

		EXEC sp_executesql @SQLString
			,@ParmDefinition
			,@Yes
			,@No
			,@None;

		RETURN(0);
	END -- End all Sysobjects

	-- Make sure the @ObjectName is local to the current database.
	SELECT @ObjShortName = PARSENAME(@ObjectName,1);
	SELECT @DbName = PARSENAME(@ObjectName,3);
	IF @DbName IS NULL
		SELECT @DbName = DB_NAME();
	ELSE IF @DbName <> DB_NAME()
		BEGIN
			RAISERROR(15250,-1,-1);
		END

	-- @ObjectName must be either sysobjects or systypes: first look in sysobjects
	SET @SQLString = N'SELECT @ObjID			= object_id
							, @SysObj_Type		= type
						FROM sys.all_objects
						WHERE object_id = OBJECT_ID(@ObjectName);';
	SET @ParmDefinition = N'@ObjectName SYSNAME
						,@ObjID INT OUTPUT
						,@SysObj_Type VARCHAR(5) OUTPUT';

	EXEC sp_executesql @SQLString
		,@ParmDefinition
		,@ObjectName
		,@ObjID OUTPUT
		,@SysObj_Type OUTPUT;

	-- If @ObjectName not in sysobjects, try systypes
	IF @ObjID IS NULL
	BEGIN
		SET @SQLString = N'SELECT @ObjID = user_type_id
							FROM sys.types
							WHERE name = PARSENAME(@ObjectName,1);';
		SET @ParmDefinition = N'@ObjectName SYSNAME
							,@ObjID INT OUTPUT';

		EXEC sp_executesql @SQLString
			,@ParmDefinition
			,@ObjectName
			,@ObjID OUTPUT;

		-- If not in systypes, return
		IF @ObjID IS NULL
		BEGIN
			RAISERROR(15009,-1,-1,@ObjectName,@DbName);
		END

		-- Data Type help (prec/scale only valid for numerics)
		SET @SQLString = N'SELECT
						[Type_name]			= t.name,
						[Storage_type]		= type_name(system_type_id),
						[Length]			= max_length,
						[Prec]				= [precision],
						[Scale]				= [scale],
						[Nullable]			= case when is_nullable=1 then @Yes else @No end,
						[Default_name]		= isnull(object_name(default_object_id), @None),
						[Rule_name]			= isnull(object_name(rule_object_id), @None),
						[Collation]			= collation_name,
						[ExtendedProperty]	= ep.[value]
					FROM [sys].[types] AS [t]
						LEFT JOIN [sys].[extended_properties] AS [ep] ON [ep].[major_id] = [t].[user_type_id]
							AND [ep].[name] = @ExtendedPropertyName
							AND [ep].[minor_id] = 0
							AND [ep].[class] = 6
					WHERE [user_type_id] = @ObjID';
		SET @ParmDefinition = N'@ObjID INT, @Yes VARCHAR(5), @No VARCHAR(5), @None VARCHAR(5), @ExtendedPropertyName SYSNAME';

		EXECUTE sp_executesql @SQLString
			,@ParmDefinition
			,@ObjID
			,@Yes
			,@No
			,@None
			,@ExtendedPropertyName;

		RETURN(0);
	END --Systypes

	-- FOUND IT IN SYSOBJECT, SO GIVE OBJECT INFO
	SET @SQLString = N'SELECT
		[Name]					= [o].[name],
		[Owner]					= USER_NAME(ObjectProperty([o].[object_id], ''ownerid'')),
		[Type]					= LOWER(REPLACE([o].[type_desc], ''_'', '' '')),
		[Created_datetime]		= [o].[create_date],
		[Modify_datetime]		= [o].[modify_date],
		[ExtendedProperty]		= [ep].[value]
	FROM [sys].[all_objects] [o]
		LEFT JOIN [sys].[extended_properties] [ep] ON [ep].[major_id] = [o].[object_id]
			AND [ep].[name] = @ExtendedPropertyName
			AND [ep].[minor_id] = 0
			AND [ep].[class] = 1
	WHERE [o].[object_id] = @ObjID;';

	SET @ParmDefinition = N'@ObjID INT, @ExtendedPropertyName SYSNAME';

	EXEC sp_executesql @SQLString
		,@ParmDefinition
		,@ObjID
		,@ExtendedPropertyName;

	-- Display column metadata if table / view
	SET @SQLString = N'
	IF EXISTS (SELECT * FROM [sys].[all_columns] WHERE [object_id] = @ObjID)
	BEGIN;

		-- SET UP NUMERIC TYPES: THESE WILL HAVE NON-BLANK PREC/SCALE
		-- There must be a '','' immediately after each type name (including last one),
		-- because that''s what we''ll search for in charindex later.
		DECLARE @precscaletypes NVARCHAR(150);
		SELECT @precscaletypes = N''tinyint,smallint,decimal,int,bigint,real,money,float,numeric,smallmoney,date,time,datetime2,datetimeoffset,''

		-- INFO FOR EACH COLUMN
		SELECT
			[Column_name]			= [ac].[name],
			[Type]					= TYPE_NAME([ac].[user_type_id]),
			[Computed]				= CASE WHEN ColumnProperty([object_id], [ac].[name], ''IsComputed'') = 0 THEN ''no'' ELSE ''yes'' END,
			[Length]				= CONVERT(INT, [ac].[max_length]),
			-- for prec/scale, only show for those types that have valid precision/scale
			-- Search for type name + '','', because ''datetime'' is actually a substring of ''datetime2'' and ''datetimeoffset''
			[Prec]					= CASE WHEN CHARINDEX(type_name([ac].[system_type_id]) + '','', '''') > 0
										THEN CONVERT(char(5),ColumnProperty([object_id], [ac].[name], ''precision''))
										ELSE ''     '' END,
			[Scale]					= CASE WHEN CHARINDEX(type_name([ac].[system_type_id]) + '','', '''') > 0
										THEN CONVERT(char(5),OdbcScale([ac].[system_type_id],[ac].[scale]))
										ELSE ''     '' END,
			[Nullable]				= CASE WHEN [ac].[is_nullable] = 0 THEN ''no'' ELSE ''yes'' END, ';

			--Only include if they exist on the current version
			IF @HasMasked = 1
				BEGIN
					SET @SQLString = @SQLString +  N'[Masked] = CASE WHEN [is_masked] = 0 THEN ''no'' ELSE ''yes'' END, ';
				END

			SET @SQLString = @SQLString + N'[Sparse] = CASE WHEN [is_sparse] = 0 THEN ''no'' ELSE ''yes'' END, ';

			IF @HasHidden = 1
				BEGIN
					SET @SQLString = @SQLString +  N'[Hidden] = CASE WHEN [is_hidden] = 0 THEN ''no'' ELSE ''yes'' END, ';
				END

			SET @SQLString = @SQLString + N'
			[Identity]				= CASE WHEN [is_identity] = 0 THEN ''no'' ELSE ''yes'' END,
			[TrimTrailingBlanks]	= CASE ColumnProperty([object_id], [ac].[name], ''UsesAnsiTrim'')
										WHEN 1 THEN ''no''
										WHEN 0 THEN ''yes''
										ELSE ''(n/a)'' END,
			[FixedLenNullInSource]	= CASE
										WHEN type_name([ac].[system_type_id]) NOT IN (''varbinary'',''varchar'',''binary'',''char'')
											THEN ''(n/a)''
										WHEN [ac].[is_nullable] = 0 THEN ''no'' ELSE ''yes'' END,
			[Collation]				= [ac].[collation_name],
			[ExtendedProperty]		= [ep].[value]
		FROM [sys].[all_columns] AS [ac]
			LEFT JOIN [sys].[extended_properties] [ep] ON [ep].[minor_id] = [ac].[column_id]
				AND [ep].[major_id] = [ac].[object_id]
				AND [ep].[name] = @ExtendedPropertyName
				AND [ep].[class] = 1
		WHERE [ac].[object_id] = @ObjID
	END';
	SET @ParmDefinition = N'@ObjID INT, @ExtendedPropertyName SYSNAME';
	EXEC sp_executesql @SQLString, @ParmDefinition, @ObjID = @ObjID, @ExtendedPropertyName = @ExtendedPropertyName;

	-- Identity & rowguid columns
	IF @SysObj_Type IN ('S ','U ','V ','TF')
	BEGIN
		DECLARE @colname SYSNAME = NULL;
		SET @SQLString = N'SELECT @colname = COL_NAME(@ObjID, column_id)
						FROM sys.identity_columns
						WHERE object_id = @ObjID;';
		SET @ParmDefinition = N'@ObjID INT, @colname SYSNAME OUTPUT';

		EXEC sp_executesql @SQLString
			,@ParmDefinition
			,@ObjID
			,@colname OUTPUT;

		--Identity
		IF (@colname IS NOT NULL)
			SELECT
				'Identity'				= @colname,
				'Seed'					= IDENT_SEED(@ObjectName),
				'Increment'				= IDENT_INCR(@ObjectName),
				'Not For Replication'	= COLUMNPROPERTY(@ObjID, @colname, 'IsIDNotForRepl');
		ELSE
			BEGIN
				SET @Msg = 'No identity is defined on object %ls.';
				RAISERROR(@Msg, 10, 1, @ObjectName) WITH NOWAIT;
			END

		-- Rowguid
		SET @colname = NULL;
		SET @SQLString = N'SELECT @colname = [name]
						FROM sys.all_columns
						WHERE [object_id] = @ObjID AND is_rowguidcol = 1;';
		SET @ParmDefinition = N'@ObjID INT, @colname SYSNAME OUTPUT';

		EXEC sp_executesql @SQLString
			,@ParmDefinition
			,@ObjID
			,@colname OUTPUT;

		IF (@colname IS NOT NULL)
			SELECT 'RowGuidCol' = @colname;
		ELSE
			BEGIN
				SET @Msg = 'No rowguid is defined on object %ls.';
				RAISERROR(@Msg, 10, 1, @ObjectName) WITH NOWAIT;
			END
	END

	-- Display any procedure parameters
	SET @SQLString = N'SELECT TOP (1) @HasParam = 1 FROM sys.all_parameters WHERE object_id = @ObjID';
	SET @ParmDefinition = N'@ObjID INT, @HasParam BIT OUTPUT';

	EXEC sp_executesql @SQLString
		,@ParmDefinition
		,@ObjID
		,@HasParam OUTPUT;

	--If parameters exist, show them
	IF @HasParam = 1
	BEGIN
		SET @SQLString = N'SELECT
			[Parameter_name]	= [name],
			[Type]				= TYPE_NAME(user_type_id),
			[Length]			= max_length,
			[Prec]				= CASE WHEN TYPE_NAME(system_type_id) = ''uniqueidentifier'' THEN [precision]
									ELSE OdbcPrec(system_type_id, max_length, [precision]) END,
			[Scale]				= ODBCSCALE(system_type_id, scale),
			[Param_order]		= parameter_id,
			[Collation]			= CONVERT([sysname], CASE WHEN system_type_id in (35, 99, 167, 175, 231, 239)
															THEN SERVERPROPERTY(''collation'') END)
		FROM sys.all_parameters
		WHERE [object_id] = @ObjID;';
		SET @ParmDefinition = N'@ObjID INT';

		EXEC sp_executesql  @SQLString
			,@ParmDefinition
			,@ObjID;
	END

	-- DISPLAY TABLE INDEXES & CONSTRAINTS
	IF @SysObj_Type IN ('S ','U ')
	BEGIN
		EXEC sys.sp_objectfilegroup @ObjID;

		/* Begin custom included columns for sp_helpindex */
		CREATE TABLE #sp_helpindex (
			index_name SYSNAME COLLATE database_default
			,index_description VARCHAR(210)
			,index_keys NVARCHAR(2126) COLLATE database_default  --Length (16*max_identifierLength)+(15*2)+(16*3)
			,index_includes NVARCHAR(MAX)	--Length (1023*max_identifierLength)+(15*2)+(16*3) is > 4000
		);
		INSERT INTO #sp_helpindex (index_name, index_description, index_keys)
		EXEC sys.sp_helpindex @ObjectName;

		IF EXISTS (SELECT 1 FROM #sp_helpindex)
		BEGIN
			SET @SQLString = N'
				WITH includedColumns AS (
					SELECT DISTINCT i2.name AS index_name
						, LTRIM(STUFF((
							SELECT '', '' + c.name
							FROM sys.indexes i
						INNER JOIN ' + QUOTENAME(DB_NAME()) + '.sys.index_columns ic ON i.index_id = ic.index_id
						INNER JOIN ' + QUOTENAME(DB_NAME()) + '.sys.columns c ON c.column_id = ic.column_id
					WHERE i.object_id = @ObjID
						AND ic.object_id = @ObjID
						AND c.object_id = @ObjID
						AND ic.is_included_column = 1
						AND i2.index_id = i.index_id
							FOR XML PATH(''''), TYPE).value(''.'', ''NVARCHAR(MAX)''), 1, 1, '''')) AS included
					FROM ' + QUOTENAME(DB_NAME()) + '.sys.indexes i2
						INNER JOIN #sp_helpindex sp ON sp.index_name COLLATE database_default = i2.name
						INNER JOIN ' + QUOTENAME(DB_NAME()) + '.sys.index_columns ic ON i2.index_id = ic.index_id
					WHERE i2.object_id = @ObjID
						AND ic.object_id = @ObjID
						AND ic.is_included_column = 1
				)
				/* tsqllint-disable update-where */
				UPDATE sp
				SET sp.index_includes = ic.included
				FROM #sp_helpindex sp
					INNER JOIN includedColumns ic ON sp.index_name COLLATE database_default = ic.index_name;';
			SET @ParmDefinition = N'@ObjID INT';

			EXEC sp_executesql @SQLString
				,@ParmDefinition
				,@ObjID;
		END
		/* tsqllint-enable update-where */

		IF EXISTS (SELECT 1 FROM #sp_helpindex)
		BEGIN
			SELECT index_name, index_description, index_keys, index_includes
			FROM #sp_helpindex;
		END
		/* End custom included columns for sp_helpindex */

		EXEC sys.sp_helpconstraint @ObjectName,'nomsg';

		SET @SQLString = N'SELECT @HasDepen = COUNT(1)
			FROM sys.objects obj, sysdepends deps
			WHERE obj.[type] =''V''
				AND obj.[object_id] = deps.id
				AND deps.depid = @ObjID
				AND deps.deptype = 1;';
		SET @ParmDefinition = N'@ObjID INT, @HasDepen INT OUTPUT';

		EXEC sp_executesql @SQLString
			,@ParmDefinition
			,@ObjID
			,@HasDepen OUTPUT;

		IF @HasDepen = 0
		BEGIN
			RAISERROR(15647,-1,-1,@ObjectName); -- No views with schemabinding for reference table '%ls'.
		END
		ELSE
		BEGIN
			SET @SQLString = N'SELECT DISTINCT [Table is referenced by views] = OBJECT_SCHEMA_NAME(obj.object_id) + ''.'' + obj.[name]
				FROM sys.objects obj
					INNER JOIN sysdepends deps ON obj.object_id = deps.id
				WHERE obj.[type] =''V''
					AND deps.depid = @ObjID
					AND deps.deptype = 1
				GROUP BY obj.[name], obj.object_id;';
			SET @ParmDefinition = N'@ObjID INT';

			EXEC sp_executesql @SQLString
				,@ParmDefinition
				,@ObjID;
		END
	END
END;
GO

EXEC sys.sp_addextendedproperty @name=N'Description', @value=N'Drop-in alternative to sp_help. Documentation at https://expresssql.lowlydba.com' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'sp_helpme';
GO

EXEC sys.sp_addextendedproperty @name=N'@ObjectName', @value=N'Target object. Default is all objects.' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'sp_helpme';
GO

EXEC sys.sp_addextendedproperty @name=N'@ExtendedPropertyName', @value=N'Key for extended properties on objects. Default is ''Description''.' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'sp_helpme';
GO

EXEC sys.sp_addextendedproperty @name=N'@SqlMajorVersion', @value=N'Used for unit testing purposes only.' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'sp_helpme';
GO

EXEC sys.sp_addextendedproperty @name=N'@SqlMinorVersion', @value=N'Used for unit testing purposes only.' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'sp_helpme';
GO
SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

IF  EXISTS (SELECT * FROM sys.fn_listextendedproperty(N'Description' , N'SCHEMA',N'dbo', N'PROCEDURE',N'sp_sizeoptimiser', NULL,NULL))
	BEGIN;
		EXEC sys.sp_dropextendedproperty @name=N'Description' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'sp_sizeoptimiser';
	END
GO

IF  EXISTS (SELECT * FROM sys.fn_listextendedproperty(N'Description' , N'SCHEMA',N'dbo', N'TYPE',N'SizeOptimiserTableType', NULL,NULL))
	BEGIN;
		EXEC sys.sp_dropextendedproperty @name=N'Description' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TYPE',@level1name=N'SizeOptimiserTableType';
	END
GO

IF  EXISTS (SELECT * FROM sys.fn_listextendedproperty(N'@SqlMinorVersion' , N'SCHEMA',N'dbo', N'PROCEDURE',N'sp_sizeoptimiser', NULL,NULL))
	BEGIN;
		EXEC sys.sp_dropextendedproperty @name=N'@SqlMinorVersion' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'sp_sizeoptimiser';
	END
GO

IF  EXISTS (SELECT * FROM sys.fn_listextendedproperty(N'@SqlMajorVersion' , N'SCHEMA',N'dbo', N'PROCEDURE',N'sp_sizeoptimiser', NULL,NULL))
	BEGIN;
		EXEC sys.sp_dropextendedproperty @name=N'@SqlMajorVersion' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'sp_sizeoptimiser';
	END
GO

IF  EXISTS (SELECT * FROM sys.fn_listextendedproperty(N'@IndexNumThreshold' , N'SCHEMA',N'dbo', N'PROCEDURE',N'sp_sizeoptimiser', NULL,NULL))
	BEGIN;
		EXEC sys.sp_dropextendedproperty @name=N'@IndexNumThreshold' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'sp_sizeoptimiser';
	END
GO

IF  EXISTS (SELECT * FROM sys.fn_listextendedproperty(N'@IncludeDatabases' , N'SCHEMA',N'dbo', N'PROCEDURE',N'sp_sizeoptimiser', NULL,NULL))
	BEGIN;
		EXEC sys.sp_dropextendedproperty @name=N'@IncludeDatabases' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'sp_sizeoptimiser';
	END
GO

IF  EXISTS (SELECT * FROM sys.fn_listextendedproperty(N'@ExcludeDatabases' , N'SCHEMA',N'dbo', N'PROCEDURE',N'sp_sizeoptimiser', NULL,NULL))
	BEGIN;
		EXEC sys.sp_dropextendedproperty @name=N'@ExcludeDatabases' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'sp_sizeoptimiser';
	END
GO

IF  EXISTS (SELECT * FROM sys.fn_listextendedproperty(N'@IncludeSysDatabases' , N'SCHEMA',N'dbo', N'PROCEDURE',N'sp_sizeoptimiser', NULL,NULL))
	BEGIN;
		EXEC sys.sp_dropextendedproperty @name=N'@IncludeSysDatabases' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'sp_sizeoptimiser';
	END
GO

IF  EXISTS (SELECT * FROM sys.fn_listextendedproperty(N'@IncludeSSRSDatabases' , N'SCHEMA',N'dbo', N'PROCEDURE',N'sp_sizeoptimiser', NULL,NULL))
	BEGIN;
		EXEC sys.sp_dropextendedproperty @name=N'@IncludeSSRSDatabases' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'sp_sizeoptimiser';
	END
GO

IF  EXISTS (SELECT * FROM sys.fn_listextendedproperty(N'@Verbose' , N'SCHEMA',N'dbo', N'PROCEDURE',N'sp_sizeoptimiser', NULL,NULL))
	BEGIN;
		EXEC sys.sp_dropextendedproperty @name=N'@Verbose' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'sp_sizeoptimiser';
	END
GO

IF  EXISTS (SELECT * FROM sys.fn_listextendedproperty(N'@IsExpress' , N'SCHEMA',N'dbo', N'PROCEDURE',N'sp_sizeoptimiser', NULL,NULL))
	BEGIN;
		EXEC sys.sp_dropextendedproperty @name=N'@IsExpress' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'sp_sizeoptimiser';
	END
GO

/******************************/
/* Cleanup existing versions  */
/******************************/
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_sizeoptimiser]'))
	BEGIN
		DROP PROCEDURE [dbo].[sp_sizeoptimiser];
	END;

IF EXISTS (SELECT * FROM sys.types st JOIN sys.schemas ss ON st.schema_id = ss.schema_id WHERE st.name = N'SizeOptimiserTableType' AND ss.name = N'dbo')
	BEGIN
		DROP TYPE [dbo].[SizeOptimiserTableType];
	END;
GO

/**************************************************************/
/* Create user defined table type for database list parameter */
/**************************************************************/
IF NOT EXISTS (SELECT * FROM sys.types st JOIN sys.schemas ss ON st.schema_id = ss.schema_id WHERE st.name = N'SizeOptimiserTableType' AND ss.name = N'dbo')
	BEGIN
		CREATE TYPE [dbo].[SizeOptimiserTableType] AS TABLE(
			[database_name] [sysname] NOT NULL,
			PRIMARY KEY CLUSTERED ([database_name] ASC) WITH (IGNORE_DUP_KEY = OFF));
	END;
GO

/***************************/
/* Create stored procedure */
/***************************/
IF NOT EXISTS(SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_sizeoptimiser]'))
	BEGIN
		EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[sp_sizeoptimiser] AS';
	END;
GO

ALTER PROCEDURE [dbo].[sp_sizeoptimiser]
	@IndexNumThreshold SMALLINT = 10
	,@IncludeDatabases [dbo].[SizeOptimiserTableType] READONLY
	,@ExcludeDatabases [dbo].[SizeOptimiserTableType] READONLY
	,@IncludeSysDatabases BIT = 0
	,@IncludeSSRSDatabases BIT = 0
	,@Verbose BIT = 1
	/* Parameters defined here for testing only */
	,@IsExpress BIT = NULL
	,@SqlMajorVersion TINYINT = NULL
	,@SqlMinorVersion SMALLINT = NULL

WITH RECOMPILE
AS

/*
sp_sizeoptimiser - Recommends space saving measures for data footprints.

Part of the DBA MultiTool http://dba-multitool.org

Version: 20220818

MIT License

Copyright (c) 2023 John McCall

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

	DECLARE @include SizeOptimiserTableType;

	INSERT INTO @include ([database_name])
	VALUES (N'WideWorldImporters');

	EXEC [dbo].[sp_sizeoptimiser] @IncludeDatabases = @include
*/

BEGIN
	SET NOCOUNT ON;

	BEGIN TRY

		DECLARE @HasTempStat BIT = 0
			,@HasPersistedSamplePercent BIT	= 0
			,@CheckNumber TINYINT = 0
            ,@EngineEdition TINYINT
			,@CheckSQL NVARCHAR(MAX) = N''
			,@Msg NVARCHAR(MAX)	= N''
			,@DbName SYSNAME = N''
			,@TempCheckSQL NVARCHAR(MAX) = N''
			,@BaseURL VARCHAR(1000) = 'http://dba-multitool.org/';

		/* Validate @IndexNumThreshold */
		IF (@IndexNumThreshold < 1 OR @IndexNumThreshold > 999)
			BEGIN
				SET @Msg = '@IndexNumThreshold must be between 1 and 999.';
				RAISERROR(@Msg, 16, 1);
			END

		/* Validate database list */
		IF (SELECT COUNT(1) FROM @IncludeDatabases) >= 1 AND (SELECT COUNT(1) FROM @ExcludeDatabases) >= 1
			BEGIN
				SET @Msg = 'Both @IncludeDatabases and @ExcludeDatabases cannot be specified.';
				RAISERROR(@Msg, 16, 1);
			END

		CREATE TABLE #Databases (
			[database_name] SYSNAME NOT NULL);

		/* Build database list if no parameters set */
		IF (SELECT COUNT(1) FROM @IncludeDatabases) = 0 AND (SELECT COUNT(1) FROM @ExcludeDatabases) = 0
			BEGIN
				INSERT INTO #Databases
				SELECT [sd].[name]
				FROM [sys].[databases] AS [sd]
				WHERE ([sd].[database_id] > 4 OR @IncludeSysDatabases = 1)
					AND ([sd].[name] NOT IN ('ReportServer', 'ReportServerTempDB') OR @IncludeSSRSDatabases = 1)
					AND DATABASEPROPERTYEX([sd].[name], 'UPDATEABILITY') = N'READ_WRITE'
					AND DATABASEPROPERTYEX([sd].[name], 'USERACCESS') = N'MULTI_USER'
					AND DATABASEPROPERTYEX([sd].[name], 'STATUS') = N'ONLINE';
			END;
		/* Build database list from @IncludeDatabases */
		ELSE IF (SELECT COUNT(1) FROM @IncludeDatabases) >= 1
			BEGIN
				INSERT INTO #Databases
				SELECT [sd].[name]
				FROM @IncludeDatabases AS [d]
					INNER JOIN [sys].[databases] AS [sd] ON [sd].[name] COLLATE database_default = REPLACE(REPLACE([d].[database_name], '[', ''), ']', '')
				WHERE DATABASEPROPERTYEX([sd].[name], 'UPDATEABILITY') = N'READ_WRITE'
					AND DATABASEPROPERTYEX([sd].[name], 'USERACCESS') = N'MULTI_USER'
					AND DATABASEPROPERTYEX([sd].[name], 'STATUS') = N'ONLINE';

				IF (SELECT COUNT(1) FROM @IncludeDatabases) > (SELECT COUNT(1) FROM #Databases)
					BEGIN
						DECLARE @ErrorDatabaseList NVARCHAR(MAX);

						WITH ErrorDatabase AS(
							SELECT [database_name]
							FROM @IncludeDatabases
							EXCEPT
							SELECT [database_name]
							FROM #Databases)

						SELECT @ErrorDatabaseList = ISNULL(@ErrorDatabaseList + N', ' + [database_name], [database_name])
						FROM ErrorDatabase;

						SET @Msg = 'Supplied databases do not exist or are not accessible: ' + @ErrorDatabaseList + '.';
						RAISERROR(@Msg, 16, 1);
					END;
			END;
		/* Build database list from @ExcludeDatabases */
		ELSE IF (SELECT COUNT(1) FROM @ExcludeDatabases) >= 1
			BEGIN
				INSERT INTO #Databases
				SELECT [sd].[name]
				FROM [sys].[databases] AS [sd]
				WHERE NOT EXISTS (SELECT [d].[database_name]
									FROM @IncludeDatabases AS [d]
									WHERE [sd].[name] COLLATE database_default = REPLACE(REPLACE([d].[database_name], '[', ''), ']', ''))
					AND DATABASEPROPERTYEX([sd].[name], 'UPDATEABILITY') = N'READ_WRITE'
					AND DATABASEPROPERTYEX([sd].[name], 'USERACCESS') = N'MULTI_USER'
					AND DATABASEPROPERTYEX([sd].[name], 'STATUS') = N'ONLINE'
				AND [sd].[name] <> 'tempdb';
			END

		/* Find edition */
		IF (@IsExpress IS NULL AND CAST(SERVERPROPERTY('Edition') AS VARCHAR(50)) LIKE 'Express%')
			BEGIN
				SET @IsExpress = 1;
			END;
		ELSE IF (@IsExpress IS NULL)
			BEGIN;
				SET @IsExpress = 0;
			END;

        /* Find engine edition */
		IF (@EngineEdition IS NULL)
			BEGIN
				SET @EngineEdition = CAST(SERVERPROPERTY('EditionEdition') AS TINYINT);
			END;

		/* Find Version */
		IF (@SqlMajorVersion IS NULL)
        	BEGIN;
            	SET @SqlMajorVersion = CAST(SERVERPROPERTY('ProductMajorVersion') AS TINYINT);
        	END;
		IF (@SqlMinorVersion IS NULL)
        	BEGIN;
            	SET @SqlMinorVersion = CAST(SERVERPROPERTY('ProductMinorVersion') AS SMALLINT);
       		END;

		/* Validate Version */
		IF (@SqlMajorVersion < 11)
			BEGIN;
				SET @Msg = 'SQL Server versions below 2012 are not supported, sorry!';
				RAISERROR(@Msg, 16, 1);
			END;

		/* Check for is_temp value on statistics */
		IF 1 = (SELECT 1 FROM [sys].[all_columns] AS [ac] WHERE [ac].[name] = 'is_temporary' AND OBJECT_NAME([ac].[object_id]) = 'all_columns')
			 BEGIN;
				 SET @HasTempStat = 1;
			 END;

		/* Check for Persisted Sample Percent update */
		IF 1 = (SELECT 1 FROM [sys].[all_columns] AS [ac] WHERE [ac].[name] = 'persisted_sample_percent' AND OBJECT_NAME([ac].[object_id]) = 'dm_db_stats_properties')
			BEGIN;
				SET @HasPersistedSamplePercent = 1;
			END;

		IF (@Verbose = 1)
			BEGIN;
				/* Print info */
				SET @Msg = 'sp_sizeoptimiser';
				RAISERROR(@Msg, 10, 1) WITH NOWAIT;
				SET @Msg = '------------';
				RAISERROR(@Msg, 10, 1) WITH NOWAIT;
				SET @Msg = CONCAT('Time: ', GETDATE());
				RAISERROR(@Msg, 10, 1) WITH NOWAIT;
				SET @Msg = CONCAT('SQL Major Version: ', @SqlMajorVersion);
				RAISERROR(@Msg, 10, 1) WITH NOWAIT;
				SET @Msg = CONCAT('SQL Minor Version: ', @SqlMinorVersion);
				RAISERROR(@Msg, 10, 1) WITH NOWAIT;
				SET @Msg = CONCAT('Is Express Edition: ', @IsExpress);
				RAISERROR(@Msg, 10, 1) WITH NOWAIT;
				SET @Msg = CONCAT('Is feature "persisted sample percent" available: ', @HasPersistedSamplePercent);
				RAISERROR(@Msg, 10, 1) WITH NOWAIT;
				SET @Msg = CONCAT(CHAR(13), CHAR(10));
				RAISERROR(@Msg, 10, 1) WITH NOWAIT;
			END;

		/* Build temp tables */
		IF OBJECT_ID(N'tempdb..#results') IS NOT NULL
			BEGIN;
				DROP TABLE #results;
			END;

		CREATE TABLE #results
			([check_num]	INT NOT NULL,
			[check_type]	NVARCHAR(50) NOT NULL,
			[db_name]		SYSNAME NOT NULL,
			[obj_type]		SYSNAME NOT NULL,
			[obj_name]		NVARCHAR(400) NOT NULL,
			[col_name]		SYSNAME NULL,
			[message]		NVARCHAR(500) NULL,
			[ref_link]		NVARCHAR(500) NULL);

		IF OBJECT_ID('tempdb..#DuplicateIndex') IS NOT NULL
			BEGIN;
				DROP TABLE #DuplicateIndex;
			END;

		CREATE TABLE #DuplicateIndex
			([check_type]	NVARCHAR(50) NOT NULL
			,[obj_type]		SYSNAME NOT NULL
			,[db_name]		SYSNAME NOT NULL
			,[obj_name]		SYSNAME NOT NULL
			,[col_name]		SYSNAME NULL
			,[message]		NVARCHAR(500) NULL
			,[object_id]	INT NOT NULL
			,[index_id]		INT NOT NULL);

		IF OBJECT_ID('tempdb..#OverlappingIndex') IS NOT NULL
			BEGIN;
				DROP TABLE #OverlappingIndex;
			END;

		CREATE TABLE #OverlappingIndex
			([check_type]	NVARCHAR(50) NOT NULL
			,[obj_type]		SYSNAME NOT NULL
			,[db_name]		SYSNAME NOT NULL
			,[obj_name]		SYSNAME NOT NULL
			,[col_name]		SYSNAME NULL
			,[message]		NVARCHAR(500) NULL
			,[object_id]	INT NOT NULL
			,[index_id]		INT NOT NULL);

		/* Header row */
		INSERT INTO #results ([check_num], [check_type], [obj_type], [db_name], [obj_name], [col_name], [message], [ref_link])
		SELECT	@CheckNumber
				,N'Lets do this'
				,N'Vroom vroom'
				,N'beep boop'
				,N'Off to the races'
				,N'Ready set go'
				,N'Thanks for using'
				,@BaseURL;

		/* Date & Time Data Type Usage */
		SET @CheckNumber = @CheckNumber + 1;
		IF (@Verbose = 1)
			BEGIN;
				SET @Msg = CONCAT(N'Check ', @CheckNumber, ' - Date and Time Data Types');
				RAISERROR(@Msg, 10, 1) WITH NOWAIT;
			END;
		BEGIN;
			SET @CheckSQL = N'';
			SELECT @CheckSQL = @CheckSQL +
				N'USE ' + QUOTENAME([database_name]) + N';
				INSERT INTO #results ([check_num], [check_type], [obj_type], [db_name], [obj_name], [col_name], [message], [ref_link])
				SELECT 	@CheckNumber
						,N''Data Types''
						,N''USER_TABLE''
						,QUOTENAME(DB_NAME())
						,QUOTENAME(SCHEMA_NAME([t].[schema_id])) + ''.'' + QUOTENAME([t].[name])
						,QUOTENAME([c].[name])
						,N''Columns storing date or time should use a temporal specific data type, but this column is using '' + ty.name + ''.''
						,CONCAT(@BaseURL COLLATE database_default, ''time-based-formats'')
				FROM [sys].[columns] AS [c]
					INNER JOIN [sys].[tables] AS [t] on [t].[object_id] = [c].[object_id]
					INNER JOIN [sys].[types] AS [ty] on [ty].[user_type_id] = [c].[user_type_id]
				WHERE [c].[is_identity] = 0 --exclude identity cols
					AND [t].[is_ms_shipped] = 0 --exclude sys table
					AND ([c].[name] LIKE ''%date%'' OR [c].[name] LIKE ''%time%'')
					AND [c].[name] NOT LIKE ''%UpdatedBy%''
					AND [c].[name] NOT LIKE ''%days%''
					AND ([c].[name] <> ''timestamp'' AND [ty].[name] NOT IN (''timestamp'', ''rowversion''))
					AND [ty].[name] NOT IN (''datetime'', ''datetime2'', ''datetimeoffset'', ''date'', ''smalldatetime'', ''time'');'
			FROM #Databases;
			EXEC sp_executesql @CheckSQL, N'@CheckNumber TINYINT, @BaseURL VARCHAR(1000)', @CheckNumber = @CheckNumber, @BaseURL = @BaseURL;
		 END; --Date and Time Data Type Check

		/* Archaic varchar Lengths (255/256) */
		SET @CheckNumber = @CheckNumber + 1;
		IF (@Verbose = 1)
			BEGIN;
				SET @Msg = CONCAT(N'Check ', @CheckNumber, ' - Archaic varchar Lengths');
				RAISERROR(@Msg, 10, 1) WITH NOWAIT;
			END;
		BEGIN;
			SET @CheckSQL = N'';
			SELECT @CheckSQL = @CheckSQL +
				N'USE ' + QUOTENAME([database_name]) +  N'; WITH archaic AS (
				SELECT 	QUOTENAME(SCHEMA_NAME(t.schema_id)) + ''.'' + QUOTENAME(t.name) AS [obj_name]
						,QUOTENAME(c.name) AS [col_name]
						,N''Possible arbitrary variable length column in use. Is the '' + ty.name + N'' length of '' + CAST (c.max_length / 2 AS varchar(MAX)) + N'' based on requirements?'' AS [message]
						,CONCAT(@BaseURL COLLATE database_default, ''arbitrary-varchar-length'') AS [ref_link]
				FROM sys.columns c
					INNER JOIN sys.tables as t on t.object_id = c.object_id
					INNER JOIN sys.types as ty on ty.user_type_id = c.user_type_id
				WHERE c.is_identity = 0 --exclude identity cols
					AND t.is_ms_shipped = 0 --exclude sys table
					AND ty.name = ''NVARCHAR''
					AND c.max_length IN (510, 512)
				UNION
				SELECT QUOTENAME(SCHEMA_NAME(t.schema_id)) + ''.'' + QUOTENAME(t.name)
						,QUOTENAME(c.name)
						,N''Possible arbitrary variable length column in use. Is the '' + ty.name + N'' length of '' + CAST (c.max_length AS varchar(MAX)) + N'' based on requirements?''
						,CONCAT(@BaseURL COLLATE database_default, ''arbitrary-varchar-length'')
				FROM sys.columns as c
					INNER JOIN sys.tables as t on t.object_id = c.object_id
					INNER JOIN sys.types as ty on ty.user_type_id = c.user_type_id
				WHERE c.is_identity = 0 --exclude identity cols
					AND t.is_ms_shipped = 0 --exclude sys table
					AND ty.name = ''VARCHAR''
					AND c.max_length IN (255, 256))

			INSERT INTO #results ([check_num], [check_type], [obj_type], [db_name], [obj_name], [col_name], [message], [ref_link])
			SELECT 	@CheckNumber
					,N''Data Types''
					,N''USER_TABLE''
					,QUOTENAME(DB_NAME())
					,[obj_name]
					,[col_name]
					,[message]
					,[ref_link]
			FROM [archaic];'
			FROM #Databases;
			EXEC sp_executesql @CheckSQL, N'@CheckNumber TINYINT, @BaseURL VARCHAR(1000)', @CheckNumber = @CheckNumber, @BaseURL = @BaseURL;
		END; --Archaic varchar Lengths

		/* Unspecified VARCHAR Length */
		SET @CheckNumber = @CheckNumber + 1;
		IF (@Verbose = 1)
			BEGIN;
				SET @Msg = CONCAT(N'Check ', @CheckNumber,' - Unspecified VARCHAR Length');
				RAISERROR(@Msg, 10, 1) WITH NOWAIT;
			END;
		BEGIN;
			SET @CheckSQL = N'';
			SELECT @CheckSQL = @CheckSQL +
				N'USE ' + QUOTENAME([database_name]) + ';
				WITH UnspecifiedVarChar AS (
					SELECT	QUOTENAME(SCHEMA_NAME(t.schema_id)) + ''.'' + QUOTENAME(t.name) AS [obj_name]
							,QUOTENAME(c.name) AS [col_name]
							,N''VARCHAR column without specified length, it should not have a length of '' + CAST (c.max_length AS varchar(10)) + '''' AS [message]
							,CONCAT(@BaseURL COLLATE database_default, ''unspecified-varchar-length'') AS [ref_link]
					FROM sys.columns as c
						INNER JOIN sys.tables as t on t.object_id = c.object_id
						INNER JOIN sys.types as ty on ty.user_type_id = c.user_type_id
					WHERE c.is_identity = 0 	--exclude identity cols
						AND t.is_ms_shipped = 0 --exclude sys table
						AND ty.name IN (''VARCHAR'', ''NVARCHAR'')
						AND c.max_length = 1)

				INSERT INTO #results ([check_num], [check_type], [obj_type], [db_name], [obj_name], [col_name], [message], [ref_link])
				SELECT	@CheckNumber
						,N''Data Types''
						,N''USER_TABLE''
						,QUOTENAME(DB_NAME())
						,[obj_name]
						,[col_name]
						,[message]
						,[ref_link]
				FROM [UnspecifiedVarChar];'
			FROM #Databases;
			EXEC sp_executesql @CheckSQL, N'@CheckNumber TINYINT, @BaseURL VARCHAR(1000)', @CheckNumber = @CheckNumber, @BaseURL = @BaseURL;
		END; --Unspecified VARCHAR Length

		/* Mad MAX - Varchar(MAX) */
		SET @CheckNumber = @CheckNumber + 1;
		IF (@Verbose = 1)
			BEGIN;
				SET @Msg = CONCAT(N'Check ', @CheckNumber, ' - Mad MAX VARCHAR');
				RAISERROR(@Msg, 10, 1) WITH NOWAIT;
			END;
		BEGIN;
			SET @CheckSQL = N'';
			SELECT @CheckSQL = @CheckSQL +
				N'USE ' + QUOTENAME([database_name]) + N';
				INSERT INTO #results ([check_num], [check_type], [obj_type], [db_name], [obj_name], [col_name], [message], [ref_link])
				SELECT @CheckNumber
						,N''Data Types''
						,N''USER_TABLE''
						,QUOTENAME(DB_NAME())
						,QUOTENAME(SCHEMA_NAME(t.schema_id)) + ''.'' + QUOTENAME(t.name)
						,QUOTENAME(c.name)
						,N''Column is NVARCHAR(MAX) which allows very large row sizes. Consider a character limit.''
						,CONCAT(@BaseURL COLLATE database_default, ''mad-varchar-max'')
				FROM sys.columns as c
						INNER JOIN sys.tables as t on t.object_id = c.object_id
						INNER JOIN sys.types as ty on ty.user_type_id = c.user_type_id
				WHERE t.is_ms_shipped = 0 --exclude sys table
						AND ty.[name] = ''nvarchar''
						AND c.max_length = -1;'
			FROM #Databases;
			EXEC sp_executesql @CheckSQL, N'@CheckNumber TINYINT, @BaseURL VARCHAR(1000)', @CheckNumber = @CheckNumber, @BaseURL = @BaseURL;
		END; --NVARCHAR MAX Check

		/* NVARCHAR data type in Express */
		SET @CheckNumber = @CheckNumber + 1;
		IF (@Verbose = 1)
			BEGIN;
				SET @Msg = CONCAT(N'Check ', @CheckNumber, ' - Use of NVARCHAR (EXPRESS)');
				RAISERROR(@Msg, 10, 1) WITH NOWAIT;
			END;
		BEGIN;
			IF (@IsExpress = 1)
				BEGIN;
					SET @CheckSQL = N'';
					SELECT @CheckSQL = @CheckSQL +
						N'USE ' + QUOTENAME([database_name]) + N';
						INSERT INTO #results ([check_num], [check_type], [obj_type], [db_name], [obj_name], [col_name], [message], [ref_link])
						SELECT	@CheckNumber
								,N''Data Types''
								,N''USER_TABLE''
								,QUOTENAME(DB_NAME())
								,QUOTENAME(SCHEMA_NAME([o].schema_id)) + ''.'' + QUOTENAME(OBJECT_NAME([o].object_id))
								,QUOTENAME([ac].[name])
								,N''nvarchar columns take 2x the space per char of varchar. Only use if you need Unicode characters.''
								,CONCAT(@BaseURL COLLATE database_default, ''nvarchar-in-express'')
						FROM   [sys].[all_columns] AS [ac]
								INNER JOIN [sys].[types] AS [t] ON [t].[user_type_id] = [ac].[user_type_id]
								INNER JOIN [sys].[objects] AS [o] ON [o].object_id = [ac].object_id
						WHERE  [t].[name] = ''NVARCHAR''
								AND [o].[is_ms_shipped] = 0'
					FROM #Databases;
					EXEC sp_executesql @CheckSQL, N'@CheckNumber TINYINT, @BaseURL VARCHAR(1000)', @CheckNumber = @CheckNumber, @BaseURL = @BaseURL;
				 END; --NVARCHAR Use Check
			ELSE IF (@Verbose = 1) --Skip check
				BEGIN;
					RAISERROR('	Skipping check, not Express...', 10, 1) WITH NOWAIT;
				END; -- Skip check
		END; --NVARCHAR Use Check

		/* FLOAT and REAL data types */
		SET @CheckNumber = @CheckNumber + 1;
		IF (@Verbose = 1)
			BEGIN;
				SET @Msg =CONCAT(N'Check ', @CheckNumber, ' - Use of FLOAT/REAL data types');
				RAISERROR(@Msg, 10, 1) WITH NOWAIT;
			END;
		BEGIN;
			SET @CheckSQL = N'';
			SELECT @CheckSQL = @CheckSQL +
				N'USE ' + QUOTENAME([database_name]) + N';
				INSERT INTO #results ([check_num], [check_type], [obj_type], [db_name], [obj_name], [col_name], [message], [ref_link])
				SELECT 	@CheckNumber
						,N''Data Types''
						,[o].[type_desc]
						,QUOTENAME(DB_NAME())
						,QUOTENAME(SCHEMA_NAME([o].[schema_id])) + ''.'' + QUOTENAME([o].[name])
						,QUOTENAME([ac].[name])
						,N''Best practice is to use DECIMAL/NUMERIC instead of '' + UPPER([st].[name]) + '' for non floating point math.''
						,CONCAT(@BaseURL COLLATE database_default, ''float-and-real-data-types'')
				FROM [sys].[all_columns] AS [ac]
						INNER JOIN [sys].[objects] AS [o] ON [o].[object_id] = [ac].[object_id]
						INNER JOIN [sys].[systypes] AS [st] ON [st].[xtype] = [ac].[system_type_id]
				WHERE [st].[name] IN (''FLOAT'', ''REAL'')
						AND [o].[type_desc] = ''USER_TABLE'';'
			FROM #Databases;
			EXEC sp_executesql @CheckSQL, N'@CheckNumber TINYINT, @BaseURL VARCHAR(1000)', @CheckNumber = @CheckNumber, @BaseURL = @BaseURL;
		END; -- FLOAT/REAL Check

		/* Deprecated data types (NTEXT, TEXT, IMAGE) */
		SET @CheckNumber = @CheckNumber + 1;
		IF (@Verbose = 1)
			BEGIN;
				SET @Msg = CONCAT(N'Check ', @CheckNumber, ' - Deprecated data types');
				RAISERROR(@Msg, 10, 1) WITH NOWAIT;
			END;
		BEGIN;
			SET @CheckSQL = N'';
			SELECT @CheckSQL = @CheckSQL +
				N'USE ' + QUOTENAME([database_name]) + N';
				INSERT INTO #results ([check_num], [check_type], [obj_type], [db_name], [obj_name], [col_name], [message], [ref_link])
				SELECT 	@CheckNumber
						,N''Data Types''
						,[o].[type_desc]
						,QUOTENAME(DB_NAME())
						,QUOTENAME(SCHEMA_NAME(o.schema_id)) + ''.'' + QUOTENAME(o.name)
						,QUOTENAME(ac.name)
						,N''Deprecated data type in use: '' + st.name + ''.''
						,CONCAT(@BaseURL COLLATE database_default, ''deprecated-data-types'')
				FROM sys.all_columns AS ac
						INNER JOIN sys.objects AS o ON o.object_id = ac.object_id
						INNER JOIN sys.systypes AS st ON st.xtype = ac.system_type_id
				WHERE st.name IN(''NEXT'', ''TEXT'', ''IMAGE'')
						AND o.type_desc = ''USER_TABLE'';'
			FROM #Databases;
			EXEC sp_executesql @CheckSQL, N'@CheckNumber TINYINT, @BaseURL VARCHAR(1000)', @CheckNumber = @CheckNumber, @BaseURL = @BaseURL;
		END; --Don't use deprecated data types check

		/* BIGINT for identity values in Express */
		SET @CheckNumber = @CheckNumber + 1;
		IF (@Verbose = 1)
			BEGIN;
				SET @Msg = CONCAT(N'Check ', @CheckNumber, ' - BIGINT used for identity columns (EXPRESS)');
				RAISERROR(@Msg, 10, 1) WITH NOWAIT;
			END;
		BEGIN;
			IF (@IsExpress = 1)
				BEGIN;
					SET @CheckSQL = N'';
					SELECT @CheckSQL = @CheckSQL +
						N'USE ' + QUOTENAME([database_name]) + N';
						INSERT INTO #results ([check_num], [check_type], [obj_type], [db_name], [obj_name], [col_name], [message], [ref_link])
						SELECT  @CheckNumber
								,N''Data Types''
								,N''USER_TABLE''
								,QUOTENAME(DB_NAME())
								,QUOTENAME(SCHEMA_NAME(t.schema_id)) + ''.'' + QUOTENAME(t.name)
								,QUOTENAME(c.name)
								,N''BIGINT used on IDENTITY column in SQL Express. If values will never exceed 2,147,483,647 use INT instead.''
								,CONCAT(@BaseURL COLLATE database_default, ''bigint-as-identity'')
							FROM sys.columns as c
								INNER JOIN sys.tables as t on t.object_id = c.object_id
								INNER JOIN sys.types as ty on ty.user_type_id = c.user_type_id
							WHERE t.is_ms_shipped = 0 --exclude sys table
								AND ty.name = ''BIGINT''
								AND c.is_identity = 1;'
					FROM #Databases;
					EXEC sp_executesql @CheckSQL, N'@CheckNumber TINYINT, @BaseURL VARCHAR(1000)', @CheckNumber = @CheckNumber, @BaseURL = @BaseURL;
				END; -- BIGINT for identity Check
			ELSE IF (@Verbose = 1) --Skip check
				BEGIN
					RAISERROR('	Skipping check, not Express...', 10, 1) WITH NOWAIT;
				END; ----Skip check
		END; -- BIGINT for identity Check

		/* Numeric or decimal with 0 scale */
		SET @CheckNumber = @CheckNumber + 1;
		IF (@Verbose = 1)
			BEGIN;
				SET @Msg = CONCAT(N'Check ', @CheckNumber, ' - NUMERIC or DECIMAL with scale of 0');
				RAISERROR(@Msg, 10, 1) WITH NOWAIT;
			END;
		BEGIN;
			SET @CheckSQL = N'';
			SELECT @CheckSQL = @CheckSQL +
				N'USE ' + QUOTENAME([database_name]) + N';
				INSERT INTO #results ([check_num], [check_type], [obj_type], [db_name], [obj_name], [col_name], [message], [ref_link])
				SELECT 	@CheckNumber
						,N''Data Types''
						,[o].[type_desc]
						,QUOTENAME(DB_NAME())
						,QUOTENAME(SCHEMA_NAME(o.schema_id)) + ''.'' + QUOTENAME(o.name)
						,QUOTENAME(ac.name)
						,N''Column is '' + UPPER(st.name) + ''('' + CAST(ac.precision AS VARCHAR) + '','' + CAST(ac.scale AS VARCHAR) + '')''
							+ '' . Consider using an INT variety for space reduction since the scale is 0.''
						,CONCAT(@BaseURL COLLATE database_default, ''numeric-or-decimal-0-scale'')
				FROM sys.objects AS o
						INNER JOIN sys.all_columns AS ac ON ac.object_id = o.object_id
						INNER JOIN sys.systypes AS st ON st.xtype = ac.system_type_id
				WHERE ac.scale = 0
						AND ac.precision < 19
						AND st.name IN(''DECIMAL'', ''NUMERIC'')
						AND o.is_ms_shipped = 0;'
			FROM #Databases;
			EXEC sp_executesql @CheckSQL, N'@CheckNumber TINYINT, @BaseURL VARCHAR(1000)', @CheckNumber = @CheckNumber, @BaseURL = @BaseURL;
		 END; -- Numeric or decimal with 0 scale check

		/* Enum columns not implemented as foreign key */
		SET @CheckNumber = @CheckNumber + 1;
		IF (@Verbose = 1)
			BEGIN;
				SET @Msg = CONCAT(N'Check ', @CheckNumber, ' - Enum columns not implemented as foreign key.');
				RAISERROR(@Msg, 10, 1) WITH NOWAIT;
			END;
		BEGIN;
			SET @CheckSQL = N'';
			SELECT @CheckSQL = @CheckSQL +
				N'USE ' + QUOTENAME([database_name]) + N';
				INSERT INTO #results ([check_num], [check_type], [obj_type], [db_name], [obj_name], [col_name], [message], [ref_link])
				SELECT 	@CheckNumber
						,N''Data Types''
						,[o].[type_desc]
						,QUOTENAME(DB_NAME())
						,QUOTENAME(SCHEMA_NAME(o.schema_id)) + ''.'' + QUOTENAME(o.name)
						,QUOTENAME(ac.name)
						,N''Column is potentially an enum that should be a foreign key to a normalized table for data integrity, space savings, and performance.''
						,CONCAT(@BaseURL COLLATE database_default, ''enum-column-not-implemented-as-foreign-key'')
				FROM sys.objects AS o
						INNER JOIN sys.all_columns AS ac ON ac.object_id = o.object_id
						INNER JOIN sys.systypes AS st ON st.xtype = ac.system_type_id
				WHERE (ac.[name] LIKE ''%Type'' OR ac.[name] LIKE ''%Status'')
					AND o.is_ms_shipped = 0
					AND [o].[type] = ''U''
					AND st.[name] IN (''nvarchar'', ''varchar'', ''char'');'
			FROM #Databases;
			EXEC sp_executesql @CheckSQL, N'@CheckNumber TINYINT, @BaseURL VARCHAR(1000)', @CheckNumber = @CheckNumber, @BaseURL = @BaseURL;
		 END; -- Enum columns not implemented as foreign key

		/* User DB or model db  Growth set past 10GB - ONLY IF EXPRESS */
		SET @CheckNumber = @CheckNumber + 1;
		IF (@Verbose = 1)
			BEGIN;
				SET @Msg = CONCAT(N'Check ', @CheckNumber, ' - Data file growth set past 10GB (EXPRESS)');
				RAISERROR(@Msg, 10, 1) WITH NOWAIT;
			END;
		BEGIN;
			IF (@IsExpress = 1)
				BEGIN;
					SET @CheckSQL = N'';
					SELECT @CheckSQL = @CheckSQL +
						N'USE ' + QUOTENAME([database_name]) + N';
						INSERT INTO #results ([check_num], [check_type], [obj_type], [db_name], [obj_name], [col_name], [message], [ref_link])
						SELECT 	@CheckNumber
								,N''File Growth''
								,N''DATABASE''
								,QUOTENAME(DB_NAME())
								,QUOTENAME(DB_NAME(database_id))
								,NULL
								,N''Database file '' + name + '' has a maximum growth set to '' +
									CASE
										WHEN max_size = -1
											THEN ''Unlimited''
										WHEN max_size > 0
											THEN CAST((max_size / 1024) * 8 AS VARCHAR(MAX))
									END + '', which is over the user database maximum file size of 10GB.''
								,CONCAT(@BaseURL COLLATE database_default, ''database-growth-past-10GB'')
							FROM sys.master_files mf
							WHERE (max_size > 1280000 OR max_size = -1) -- greater than 10GB or unlimited
								AND [mf].[database_id] > 5
								AND [mf].[data_space_id] > 0 -- limit doesn''t apply to log files;'
					FROM #Databases;
					EXEC sp_executesql @CheckSQL, N'@CheckNumber TINYINT, @BaseURL VARCHAR(1000)', @CheckNumber = @CheckNumber, @BaseURL = @BaseURL;
				END; -- User DB or model db  Growth check
			ELSE  IF (@Verbose = 1) --Skip check
				BEGIN;
					RAISERROR('	Skipping check, not Express...', 10, 1) WITH NOWAIT;
				END;
		END; -- User DB or model db  Growth check

		/* User DB or model db growth set to % */
		SET @CheckNumber = @CheckNumber + 1;
		IF (@Verbose = 1)
			BEGIN;
				SET @Msg = CONCAT(N'Check ', @CheckNumber, ' - Data file growth set to percentage.');
				RAISERROR(@Msg, 10, 1) WITH NOWAIT;
			END;
		BEGIN;
            IF (@EngineEdition <> 5) --Not Azure SQL
              	BEGIN
			        INSERT INTO #results ([check_num], [check_type], [obj_type], [db_name], [obj_name], [col_name], [message], [ref_link])
			        SELECT @CheckNumber
					        ,N'File Growth'
					        ,N'DATABASE'
					        ,QUOTENAME(DB_NAME([sd].[database_id]))
					        ,[mf].[name]
					        ,NULL
					        ,N'Database file '+[mf].[name]+' has growth set to % instead of a fixed amount. This may grow quickly.'
					        ,CONCAT(@BaseURL, 'database-growth-type')
			        FROM [sys].[master_files] AS [mf]
				        INNER JOIN [sys].[databases] AS [sd] ON [sd].[database_id] = [mf].[database_id]
				        INNER JOIN #Databases AS [d] ON [d].[database_name] = [sd].[name]
			        WHERE [mf].[is_percent_growth] = 1
					        AND [mf].[data_space_id] = 1; --ignore log files
  				END;
		 END; -- User DB or model db growth set to % Check

		/* Default fill factor (EXPRESS ONLY) */
		SET @CheckNumber = @CheckNumber + 1;
		IF (@Verbose = 1)
			BEGIN;
				SET @Msg = CONCAT(N'Check ', @CheckNumber, ' - Non-default fill factor (EXPRESS)');
				RAISERROR(@Msg, 10, 1) WITH NOWAIT;
			END;
		BEGIN;
			IF(@IsExpress = 1)
				BEGIN;
					SET @CheckSQL = N'';
					SELECT @CheckSQL = @CheckSQL +
						N'USE ' + QUOTENAME([database_name]) + N';
						INSERT INTO #results ([check_num], [check_type], [obj_type], [db_name], [obj_name], [col_name], [message], [ref_link])
						SELECT 	@CheckNumber
								,N''Architecture''
								,N''INDEX''
								,QUOTENAME(DB_NAME())
								,QUOTENAME(SCHEMA_NAME([o].[schema_id])) + ''.'' + QUOTENAME([o].[name]) + ''.'' + QUOTENAME([i].[name])
								,NULL
								,N''Non-default fill factor on this index. Not inherently bad, but will increase table size more quickly.''
								,CONCAT(@BaseURL COLLATE database_default, ''default-fill-factor'')
						FROM [sys].[indexes] AS [i]
								INNER JOIN [sys].[objects] AS [o] ON [o].[object_id] = [i].[object_id]
						WHERE [i].[fill_factor] NOT IN(0, 100);'
					FROM #Databases;
					EXEC sp_executesql @CheckSQL, N'@CheckNumber TINYINT, @BaseURL VARCHAR(1000)', @CheckNumber = @CheckNumber, @BaseURL = @BaseURL;
				END; -- Non-default fill factor check
			ELSE IF (@Verbose = 1) --Skip check
				BEGIN;
					RAISERROR('	Skipping check, not Express...', 10, 1) WITH NOWAIT;
				END;
		END; --Default fill factor

		/* Number of indexes */
		SET @CheckNumber = @CheckNumber + 1;
		IF (@Verbose = 1)
			BEGIN;
				SET @Msg = CONCAT('Check ', @CheckNumber, ' - Questionable number of indexes');
				RAISERROR(@Msg, 10, 1) WITH NOWAIT;
			END;
		BEGIN;
			SET @CheckSQL = N'';
			SELECT @CheckSQL = @CheckSQL +
				N'USE ' + QUOTENAME([database_name]) +  N';
				INSERT INTO #results ([check_num], [check_type], [obj_type], [db_name], [obj_name], [col_name], [message], [ref_link])
				SELECT 	@CheckNumber
						,N''Architecture''
						,N''INDEX''
						,QUOTENAME(DB_NAME())
						,QUOTENAME(SCHEMA_NAME(t.schema_id)) + ''.'' + QUOTENAME(t.name)
						,NULL
						,''There are '' + CAST(COUNT(DISTINCT(i.index_id)) AS VARCHAR) + '' indexes on this table taking up '' + CAST(CAST(SUM(s.[used_page_count]) * 8 / 1024.00 AS DECIMAL(10, 2)) AS VARCHAR) + '' MB of space.''
						,CONCAT(@BaseURL COLLATE database_default, ''number-of-indexes'')
				FROM sys.indexes AS i
						INNER JOIN sys.tables AS t ON i.object_id = t.object_id
						INNER JOIN sys.dm_db_partition_stats AS s ON s.object_id = i.object_id
														AND s.index_id = i.index_id
				WHERE t.is_ms_shipped = 0 --exclude sys table
						AND i.type_desc = ''NONCLUSTERED'' --exclude clustered indexes from count
				GROUP BY t.name,
							t.schema_id
				HAVING COUNT(DISTINCT(i.index_id)) > @IndexNumThreshold;'
			FROM #Databases;
			EXEC sp_executesql @CheckSQL, N'@IndexNumThreshold TINYINT, @CheckNumber TINYINT, @BaseURL VARCHAR(1000)', @IndexNumThreshold = @IndexNumThreshold, @CheckNumber = @CheckNumber, @BaseURL = @BaseURL;
		 END; -- Questionable number of indexes check

		/* Inefficient Indexes */
		SET @CheckNumber = @CheckNumber + 1;
		IF (@Verbose = 1)
			BEGIN;
				SET @Msg = CONCAT(N'Check ', @CheckNumber, ' - Inefficient indexes');
				RAISERROR(@Msg, 10, 1) WITH NOWAIT;
			END;
		BEGIN;
			SET @CheckSQL = N'';
			SELECT @CheckSQL = @CheckSQL +
				N' USE ? ;
					BEGIN
						IF OBJECT_ID(''tempdb..#Indexes'') IS NOT NULL
						BEGIN;
							DROP TABLE [#Indexes];
						END;
						IF OBJECT_ID(''tempdb..#IdxChecksum'') IS NOT NULL
						BEGIN;
							DROP TABLE [#IdxChecksum];
						END;
						IF OBJECT_ID(''tempdb..#MatchingIdxInclChecksum'') IS NOT NULL
						BEGIN;
							DROP TABLE [#MatchingIdxInclChecksum];
						END;
						IF OBJECT_ID(''tempdb..#MatchingIdxChecksum'') IS NOT NULL
						BEGIN;
							DROP TABLE [#MatchingIdxChecksum];
						END; '

						+ /* Retrieve all indexes */ +
						N'SELECT  ac.[name] AS [col_name]
								,row_number () OVER (PARTITION BY ind.[object_id], ind.index_id ORDER BY indc.index_column_id ) AS row_num
								,ind.index_id
								,ind.[object_id]
								,DENSE_RANK() OVER (ORDER BY ind.[object_id], ind.index_id) AS [index_num]
								,indc.is_included_column
								,NULL AS [ix_checksum]
								,NULL AS [ix_incl_checksum]
								,ao.[schema_id]
						INTO #Indexes
						FROM sys.indexes as [ind]
							INNER JOIN sys.index_columns AS [indc] ON [ind].[object_id] = [indc].[object_id] AND ind.index_id = indc.index_id
							INNER JOIN sys.all_columns as [ac] ON [ac].[column_id] = [indc].[column_id] and indc.[object_id] = ac.[object_id]
							INNER JOIN sys.all_objects AS [ao] ON [ao].[object_id] = [ac].[object_id]
						WHERE ao.is_ms_shipped = 0
						ORDER BY ind.[object_id];

						DECLARE @Counter BIGINT = (SELECT 1);
						DECLARE @MaxNumIndex BIGINT = (SELECT MAX(index_num) FROM #Indexes); '

						+ /* Iterate through each index, adding together columns for each */ +
						N'WHILE @Counter <= @MaxNumIndex
						BEGIN
							DECLARE @IndexedColumns NVARCHAR(MAX) = N'''';
							DECLARE @IndexedColumnsInclude NVARCHAR(MAX) = N''''; '

							+ /* Add together index columns */ +
							N'SELECT @IndexedColumns += CAST([col_name] AS SYSNAME)
							FROM #Indexes
							WHERE is_included_column = 0
								AND index_num = @Counter
							ORDER BY row_num; '

							+ /* Add together index + included columns */ +
							N'SELECT @IndexedColumnsInclude += CAST([col_name] AS SYSNAME)
							FROM #Indexes
							WHERE index_num = @Counter
							ORDER BY row_num; '

							+ /* Generate a checksum for index columns and index + included columns for each index */ +
							N'UPDATE #Indexes
							SET [ix_checksum] = CHECKSUM(@IndexedColumns), [ix_incl_checksum] = CHECKSUM(@IndexedColumnsInclude)
							WHERE index_num = @Counter;

							SET @Counter += 1;
						END; '

						+ /* Narrow down to one row per index */ +
						N'SELECT DISTINCT [object_id], index_id, [ix_checksum], [ix_incl_checksum], [schema_id]
						INTO #IdxChecksum
						FROM #Indexes; '

						+ /* Find duplicate indexes */ +
						N'SELECT COUNT(1) AS [num_dup_indexes], [ix_incl_checksum], [object_id]
						INTO #MatchingIdxInclChecksum
						FROM #IdxChecksum
						GROUP BY [ix_incl_checksum], [object_id]
						HAVING COUNT(1) > 1; '

						+ /* Find overlapping indexes with same indexed columns */ +
						N'SELECT COUNT(1) AS [num_dup_indexes], [ix_checksum], [object_id]
						INTO #MatchingIdxChecksum
						FROM #IdxChecksum
						GROUP BY [ix_checksum], [object_id]
						HAVING COUNT(1) > 1

						INSERT INTO #DuplicateIndex
						SELECT N''Inefficient Indexes - Duplicate'' AS [check_type]
								,N''INDEX'' AS [obj_type]
								,QUOTENAME(DB_NAME()) AS [db_name]
								,QUOTENAME(SCHEMA_NAME([schema_id])) + ''.'' + QUOTENAME(OBJECT_NAME(ic.[object_id])) + ''.'' + QUOTENAME(i.[name]) AS [obj_name]
								,NULL AS [col_name]
								,''Indexes in group '' + CAST(DENSE_RANK() over (order by miic.[ix_incl_checksum]) AS VARCHAR(5)) + '' share the same indexed and any included columns.'' AS [message]
								,ic.[object_id]
								,ic.[index_id]
						FROM #MatchingIdxInclChecksum AS miic
							INNER JOIN #IdxChecksum AS ic ON ic.[object_id] = miic.[object_id] AND ic.[ix_incl_checksum] = miic.[ix_incl_checksum]
							INNER JOIN sys.indexes AS [i] ON [i].[index_id] = ic.index_id AND i.[object_id] = ic.[object_id]

						INSERT INTO #OverlappingIndex
						SELECT N''Inefficient Indexes - Overlapping'' AS [check_type]
								,N''INDEX'' AS [obj_type]
								,QUOTENAME(DB_NAME()) AS [db_name]
								,QUOTENAME(SCHEMA_NAME([schema_id])) + ''.'' + QUOTENAME(OBJECT_NAME(ic.[object_id])) + ''.'' + QUOTENAME(i.[name]) AS [obj_name]
								,NULL AS [col_name]
								,''Indexes in group '' + CAST(DENSE_RANK() OVER (order by mic.[ix_checksum]) AS VARCHAR(5)) + '' share the same indexed columns.'' AS [message]
								,ic.[object_id]
								,ic.[index_id]
						FROM #MatchingIdxChecksum AS mic
							INNER JOIN #IdxChecksum AS ic ON ic.[object_id] = mic.[object_id] AND ic.[ix_checksum] = mic.[ix_checksum]
							INNER JOIN sys.indexes AS [i] ON [i].[index_id] = ic.index_id AND i.[object_id] = ic.[object_id] '
						+ /* Dont include any indexes that are already identified as 100% duplicates */ +
						N'WHERE NOT EXISTS (SELECT * FROM #DuplicateIndex AS [di] WHERE [di].[object_id] = ic.[object_id] AND di.index_id = ic.index_id);
					END';

			DECLARE [DB_Cursor] CURSOR LOCAL FAST_FORWARD
			FOR SELECT QUOTENAME([database_name])
				FROM #Databases;

			OPEN [DB_Cursor];

			FETCH NEXT FROM [DB_Cursor]
			INTO @DbName;

			/* Run index query for each database */
			WHILE @@FETCH_STATUS = 0
				BEGIN;
					SET @TempCheckSQL = REPLACE(@CheckSQL, N'?', @DbName);
					EXEC sp_executesql @TempCheckSQL;
					FETCH NEXT FROM [DB_Cursor]
					INTO @DbName;
				END;
			CLOSE [DB_Cursor];
			DEALLOCATE [DB_Cursor];

			/* Duplicate Indexes */
			INSERT INTO #results ([check_num], [check_type], [obj_type], [db_name], [obj_name], [col_name], [message], [ref_link])
			SELECT @CheckNumber
				   ,[check_type]
				   ,[obj_type]
				   ,[db_name]
				   ,[obj_name]
				   ,[col_name]
				   ,[message]
				   ,CONCAT(@BaseURL,'inefficient-indexes')
			FROM #DuplicateIndex;

			/* Overlapping Indexes */
			INSERT INTO #results ([check_num], [check_type], [obj_type], [db_name], [obj_name], [col_name], [message], [ref_link])
			SELECT @CheckNumber
				   ,[check_type]
				   ,[obj_type]
				   ,[db_name]
				   ,[obj_name]
				   ,[col_name]
				   ,[message]
				   ,CONCAT(@BaseURL,'inefficient-indexes')
			FROM #OverlappingIndex;

		 END; -- Inefficient indexes check

		/* Sparse columns */
		SET @CheckNumber = @CheckNumber + 1;
		IF (@Verbose = 1)
			BEGIN;
				SET @Msg = CONCAT(N'Check ', @CheckNumber, ' - Sparse column eligibility');
				RAISERROR(@Msg, 10, 1) WITH NOWAIT;
			END;
		BEGIN;
			IF OBJECT_ID('tempdb..#SparseTypes') IS NOT NULL
				BEGIN;
					DROP TABLE [#SparseTypes];
				END;
			IF OBJECT_ID('tempdb..#Stats') IS NOT NULL
				BEGIN;
					DROP TABLE [#Stats];
				END;
			IF OBJECT_ID('tempdb..#StatsHeaderStaging') IS NOT NULL
				BEGIN;
					DROP TABLE [#StatsHeaderStaging];
				END;
			IF OBJECT_ID('tempdb..#StatHistogramStaging') IS NOT NULL
				BEGIN;
					DROP TABLE [#StatHistogramStaging];
				END;

			CREATE TABLE #SparseTypes (
					[ID] INT IDENTITY(1,1) NOT NULL,
					[name] VARCHAR(20),
					[user_type_id] INT,
					[scale] TINYINT NULL,
					[precision] TINYINT NOT NULL,
					[threshold_null_perc] TINYINT NOT NULL);

			CREATE CLUSTERED INDEX cidx_#sparsetypes ON #SparseTypes([ID]);

			/*	Reference values for when it makes sense to use the sparse feature based on 40% minimum space savings
				including if those recommendations change based on scale / precision. Conservative estimates are used
				when a column is in between the high and low values in the table.
				https://docs.microsoft.com/en-us/sql/relational-databases/tables/use-sparse-columns?view=sql-server-2017#estimated-space-savings-by-data-type */
			INSERT INTO #SparseTypes ([name], [user_type_id], [scale], [precision], [threshold_null_perc])
			VALUES	('BIT',104, 0,0, 98),
					('TINYINT',48, 0,0, 86),
					('SMALLINT',52, 0,0, 76),
					('INT',56, 0,0, 64),
					('BIGINT',127, 0,0, 52),
					('REAL',59, 0,0, 64),
					('FLOAT',62, 0,0, 52),
					('SMALLMONEY',122, 0,0, 64),
					('MONEY',60, 0,0, 52),
					('SMALLDATETIME',58, 0,0, 64),
					('DATETIME',61, 0,0, 52),
					('UNIQUEIDENTIFIER',36, 0,0, 43),
					('DATE',40, 0,0, 69),
					('DATETIME2',42, 0,0, 57),
					('DATETIME2',42, 7,0, 52),
					('TIME',41, 0,0, 69),
					('TIME',41, 7,0, 60),
					('DATETIMEOFFSET',43, 0,0, 52),
					('DATETIMEOFFSET',43, 7,0, 49),
					('VARCHAR',167, 0,0, 60),
					('CHAR',175, 0,0, 60),
					('NVARCHAR',231, 0,0, 60),
					('NCHAR',239, 0,0, 60),
					('VARBINARY',165, 0,0, 60),
					('BINARY',173, 0,0, 60),
					('XML',241, 0,0, 60),
					('HIERARCHYID',128, 0,0, 60),
					('DECIMAL', 106, NULL, 1, 60),
					('DECIMAL', 106, NULL, 38, 42),
					('NUMERIC', 108, NULL, 1, 60),
					('NUMERIC', 108, NULL, 38, 42);

			--For STAT_HEADER data
			CREATE TABLE #StatsHeaderStaging (
				[name] SYSNAME
				,[updated] DATETIME2(0)
				,[rows] BIGINT
				,[rows_sampled] BIGINT
				,[steps] INT
				,[density] DECIMAL(6,3)
				,[average_key_length] REAL
				,[string_index] VARCHAR(10)
				,[filter_expression] NVARCHAR(MAX)
				,[unfiltered_rows] BIGINT);

			--Check for extra persisted sample percent column
			IF @HasPersistedSamplePercent = 1
				BEGIN;
					ALTER TABLE #StatsHeaderStaging ADD [persisted_sample_percent] INT;
				END;

			--For HISTOGRAM data
			CREATE TABLE #StatHistogramStaging (
				[range_hi_key] NVARCHAR(MAX)
				,[range_rows] BIGINT
				,[eq_rows] DECIMAL(38,2)
				,[distinct_range_rows] BIGINT
				,[avg_range_rows] BIGINT);

			--For combined DBCC stat data (SHOW_STAT + HISTOGRAM)
			CREATE TABLE #Stats (
				[stats_id] INT IDENTITY(1,1)
				,[db_name] SYSNAME
				,[stat_name] SYSNAME
				,[stat_updated] DATETIME2(0)
				,[rows] BIGINT
				,[rows_sampled] BIGINT
				,[schema_name] SYSNAME
				,[table_name] SYSNAME NULL
				,[col_name] SYSNAME NULL
				,[eq_rows] BIGINT NULL
				,[null_perc] AS CAST([eq_rows] AS DECIMAL (38,2)) / NULLIF([rows], 0) * 100
				,[threshold_null_perc] SMALLINT);

			CREATE CLUSTERED INDEX cidx_#stats ON #Stats([stats_id]);

			SET @CheckSQL =
				N'	USE ?;
					BEGIN
						DECLARE	@schemaName SYSNAME
							,@tableName SYSNAME
							,@statName SYSNAME
							,@colName SYSNAME
							,@threshold_null_perc SMALLINT;

						DECLARE @DBCCSQL NVARCHAR(MAX) 		= N'''';
						DECLARE @DBCCStatSQL NVARCHAR(MAX) 	= N'''';
						DECLARE @DBCCHistSQL NVARCHAR(MAX) 	= N'''';

						DECLARE [DBCC_Cursor] CURSOR LOCAL FAST_FORWARD
						FOR
							SELECT DISTINCT	sch.name	AS [schema_name]
											,t.name		AS [table_name]
											,s.name		AS [stat_name]
											,ac.name	AS [col_name]
											,threshold_null_perc
							FROM [sys].[stats] AS [s]
								INNER JOIN [sys].[stats_columns] AS [sc] on sc.stats_id = s.stats_id
								INNER JOIN [sys].[tables] AS [t] on t.object_id = s.object_id
								INNER JOIN [sys].[schemas] AS [sch] on sch.schema_id = t.schema_id
								INNER JOIN [sys].[all_columns] AS [ac] on ac.column_id = sc.column_id
									AND [ac].[object_id] = [t].[object_id]
									AND [ac].[object_id] = [sc].[object_id]
								INNER JOIN [sys].[types] AS [typ] ON [typ].[user_type_id] = [ac].[user_type_id]
								INNER JOIN [sys].[indexes] AS [i] ON [i].[object_id] = [t].[object_id] '
								+ /* Special considerations for variable length data types */ +
								N'INNER JOIN [#SparseTypes] AS [st] ON [st].[user_type_id] = [typ].[user_type_id]
									AND (typ.name NOT IN (''DECIMAL'', ''NUMERIC'', ''DATETIME2'', ''TIME'', ''DATETIMEOFFSET''))
									OR (typ.name IN (''DECIMAL'', ''NUMERIC'') AND st.precision = ac.precision AND st.precision = 1)
									OR (typ.name IN (''DECIMAL'', ''NUMERIC'') AND ac.precision > 1 AND st.precision = 38)
									OR (typ.name IN (''DATETIME2'', ''TIME'', ''DATETIMEOFFSET'') AND st.scale = ac.scale AND st.scale = 0)
									OR (typ.name IN (''DATETIME2'', ''TIME'', ''DATETIMEOFFSET'') AND ac.scale > 0 AND st.scale = 7)
							WHERE [sc].[stats_column_id] = 1
								AND [s].[has_filter] = 0
								AND [s].[no_recompute] = 0
								AND [ac].[is_nullable] = 1
								AND NOT EXISTS (SELECT 1 -- Compressed tables not compatible with sparse cols
										FROM [sys].[partitions] AS [p]
										WHERE [p].[object_id] = [i].[object_id]
											AND [p].[data_compression] > 0) ';
			IF @HasTempStat = 1
				BEGIN;
					SET @CheckSQL = @CheckSQL + N'AND [s].[is_temporary] = 0; ';
				END;

			SET @CheckSQL = @CheckSQL + N'
						OPEN [DBCC_Cursor];

						FETCH NEXT FROM [DBCC_Cursor]
						INTO @schemaName, @tableName, @statName, @colName, @threshold_null_perc;

						WHILE @@FETCH_STATUS = 0
							BEGIN;
								DECLARE @SchemaTableName SYSNAME = QUOTENAME(@schemaName) + ''.'' + QUOTENAME(@tableName); '

								+ /* Build DBCC statistics queries */ +
								N'SET @DBCCSQL = N''DBCC SHOW_STATISTICS(@SchemaTableName, @statName)'';
								SET @DBCCStatSQL = @DBCCSQL + '' WITH STAT_HEADER, NO_INFOMSGS;'';
								SET @DBCCHistSQL = @DBCCSQL + '' WITH HISTOGRAM, NO_INFOMSGS;''; '

								+ /* Stat Header temp table */ +
								N'INSERT INTO #StatsHeaderStaging
								EXEC sp_executesql @DBCCStatSQL
									,N''@SchemaTableName SYSNAME, @statName SYSNAME''
									,@SchemaTableName = @SchemaTableName
									,@statName = @statName; '

								+ /* Histogram temp table */ +
								N'INSERT INTO #StatHistogramStaging
								EXEC sp_executesql @DBCCHistSQL
									,N''@SchemaTableName SYSNAME, @statName SYSNAME''
									,@SchemaTableName = @SchemaTableName
									,@statName = @statName;

								INSERT INTO #Stats
								SELECT	DB_NAME()
										,[head].[name]
										,[head].[updated]
										,[head].[rows]
										,[head].[rows_sampled]
										,@schemaName
										,@tableName
										,@colName
										,[hist].[eq_rows]
										,@threshold_null_perc
								FROM #StatsHeaderStaging head
									CROSS APPLY #StatHistogramStaging hist
								WHERE hist.range_hi_key IS NULL
									AND hist.eq_rows > 0
									AND head.unfiltered_rows > 0
									AND head.rows > 1000;

								TRUNCATE TABLE #StatsHeaderStaging;
								TRUNCATE TABLE #StatHistogramStaging;

								FETCH NEXT FROM DBCC_Cursor
								INTO @schemaName, @tableName, @statName, @colName, @threshold_null_perc;
							END;
						CLOSE [DBCC_Cursor];
						DEALLOCATE [DBCC_Cursor];
					END;';

			DECLARE [DB_Cursor] CURSOR LOCAL FAST_FORWARD
			FOR SELECT QUOTENAME([database_name])
				FROM #Databases;

			OPEN [DB_Cursor];

			FETCH NEXT FROM [DB_Cursor]
			INTO @DbName;

			/* Run stat query for each database */
			WHILE @@FETCH_STATUS = 0
				BEGIN;
					SET @TempCheckSQL = REPLACE(@CheckSQL, N'?', @DbName);
					EXEC sp_executesql @TempCheckSQL;
					FETCH NEXT FROM [DB_Cursor]
					INTO @DbName;
				END;
			CLOSE [DB_Cursor];
			DEALLOCATE [DB_Cursor];

			INSERT INTO #results ([check_num], [check_type], [obj_type], [db_name], [obj_name], [col_name], [message], [ref_link])
			SELECT	@CheckNumber
					,N'Architecture'
					,N'USER_TABLE'
					,QUOTENAME([db_name])
					,QUOTENAME([schema_name]) + '.' + QUOTENAME([table_name])
					,QUOTENAME([col_name])
					,N'Candidate for converting to a space-saving sparse column based on NULL distribution of more than ' + CAST([threshold_null_perc] AS VARCHAR(3))+ ' percent.'
					,CONCAT(@BaseURL, 'sparse-columns')
			FROM #Stats
			WHERE [null_perc] >= [threshold_null_perc];
		END; -- Sparse column check

		/* Heap Tables */
		SET @CheckNumber = @CheckNumber + 1;
		IF (@Verbose = 1)
			BEGIN;
				SET @Msg = CONCAT(N'Check ', @CheckNumber, ' - Heap Tables');
				RAISERROR(@Msg, 10, 1) WITH NOWAIT;
			END;
		BEGIN
			SET @CheckSQL = N'';
			SELECT @CheckSQL = @CheckSQL +
				N'USE ' + QUOTENAME([database_name]) + N';
				INSERT INTO #results ([check_num], [check_type], [obj_type], [db_name], [obj_name], [col_name], [message], [ref_link])
				SELECT 	@CheckNumber
						,N''Architecture''
						,N''INDEX''
						,QUOTENAME(DB_NAME())
						,QUOTENAME(SCHEMA_NAME([t].[schema_id])) + ''.'' + QUOTENAME([t].[name])
						,NULL
						,N''Heap tables can result in massive fragmentation and have additional indexing overhead.''
						,CONCAT(@BaseURL COLLATE database_default, ''heap-tables'')
				FROM [sys].[tables] AS [t]
						INNER JOIN [sys].[indexes] AS [i] ON [i].[object_id] = [t].[object_id]
				WHERE [i].[type] = 0'
			FROM #Databases;
			EXEC sp_executesql @CheckSQL, N'@CheckNumber TINYINT, @BaseURL VARCHAR(1000)', @CheckNumber = @CheckNumber, @BaseURL = @BaseURL;
		END; --Heap Tables

		/* Wrap it up */
		SELECT [check_num]
			,[check_type]
			,[db_name]
			,[obj_type]
			,[obj_name]
			,[col_name]
			,[message]
			,[ref_link]
		FROM #results
		ORDER BY [check_num], [check_type], [db_name], [obj_type], [obj_name], [col_name], [message];

	END TRY

	BEGIN CATCH;
		BEGIN;
			DECLARE @ErrorNumber INT = ERROR_NUMBER();
			DECLARE @ErrorLine INT = ERROR_LINE();
			DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
			DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
			DECLARE @ErrorState INT = ERROR_STATE();

			RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState) WITH NOWAIT;
			SET @Msg = CONCAT('Actual error number: ', @ErrorNumber);
			RAISERROR(@Msg, 16, 1);
			SET @Msg = CONCAT('Actual line number: ', @ErrorLine);
			RAISERROR(@Msg, 16, 1);
			SET @Msg = CONCAT('Check number: ', @CheckNumber);
			RAISERROR(@Msg, 16, 1);
		END;
	END CATCH;
END;
GO

EXEC sys.sp_addextendedproperty @name=N'Description', @value=N'Recommends space saving and corrective data type measures based on SQL Server database schemas. Documentation at https://expresssql.lowlydba.com' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'sp_sizeoptimiser';
GO

EXEC sys.sp_addextendedproperty @name=N'Description', @value=N'Required table type for sp_sizeoptimiser.' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TYPE',@level1name=N'SizeOptimiserTableType';
GO

EXEC sys.sp_addextendedproperty @name=N'@SqlMajorVersion', @value=N'Used for unit testing purposes only.' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'sp_sizeoptimiser';
GO

EXEC sys.sp_addextendedproperty @name=N'@SqlMinorVersion', @value=N'Used for unit testing purposes only.' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'sp_sizeoptimiser';
GO

EXEC sys.sp_addextendedproperty @name=N'@IndexNumThreshold', @value=N'Number of indexes to classify a table as having too many indexes on it. Default value is 10.' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'sp_sizeoptimiser';
GO

EXEC sys.sp_addextendedproperty @name=N'@IncludeDatabases', @value=N'Which databases to run the script on in the form of a user defined table type. If not supplied, all accessible user databases are targeted. Cannot be used in conjunction with @ExcludeDatabases.' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'sp_sizeoptimiser';
GO

EXEC sys.sp_addextendedproperty @name=N'@ExcludeDatabases', @value=N'Which databases to exclude in the form of a user defined table type. Cannot be used in conjunction with @IncludeDatabases.' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'sp_sizeoptimiser';
GO

EXEC sys.sp_addextendedproperty @name=N'@IncludeSysDatabases', @value=N'Whether or not to include system databases in the script''s analysis. Default is 0.' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'sp_sizeoptimiser';
GO

EXEC sys.sp_addextendedproperty @name=N'@IncludeSSRSDatabases', @value=N'Whether or not to include SQL Server Reporting Services databases in the script''s analysis. Default is 0.' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'sp_sizeoptimiser';
GO

EXEC sys.sp_addextendedproperty @name=N'@Verbose', @value=N'Whether or not to print additional information during the script run. Default is 0.' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'sp_sizeoptimiser';
GO

EXEC sys.sp_addextendedproperty @name=N'@IsExpress', @value=N'Used for unit testing purposes only.' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'sp_sizeoptimiser';
GO

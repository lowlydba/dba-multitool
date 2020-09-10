SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_doc]') AND [type] IN (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[sp_doc] AS';
END
GO

ALTER PROCEDURE [dbo].[sp_doc]
	@DatabaseName SYSNAME = NULL
	,@ExtendedPropertyName SYSNAME = 'Description'
	/* Parameters defined here for testing only */
	,@SqlMajorVersion TINYINT = 0
	,@SqlMinorVersion SMALLINT = 0
WITH RECOMPILE
AS
																									 
/*
sp_doc - Part of the ExpressSQL Suite https://expresssql.lowlydba.com/

MIT License

Copyright (c) 2020 John McCall

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
		,@LastUpdated NVARCHAR(20) = '2020-06-29';

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

	--Check database name
	IF (@DatabaseName IS NULL)
		BEGIN
			SET @DatabaseName = DB_NAME();
		END
	ELSE IF (DB_ID(@DatabaseName) IS NULL)
		BEGIN;
			SET @Msg = 'Database not available.';
			RAISERROR(@Msg, 16, 1);
		END;

	SET @QuotedDatabaseName = QUOTENAME(@DatabaseName); --Avoid injections

	--Create table to hold EP data
	SET @Sql = N'USE ' + @QuotedDatabaseName + '
	CREATE TABLE #markdown ( 
	   [id] INT IDENTITY(1,1),
	   [value] NVARCHAR(MAX));';

	/***********************
	Generate markdown for database
	************************/
	SET @Sql = @Sql + N'
	--Database Name
	INSERT INTO #markdown (value)
	VALUES (CONCAT(''# '', @DatabaseName) COLLATE DATABASE_DEFAULT);' +

	--Database extended properties
	+ N'INSERT INTO #markdown (value)
	SELECT CONCAT(CHAR(13), CHAR(10), CAST([value] AS VARCHAR(8000)))
	FROM [sys].[extended_properties]
	WHERE [class] = 0
		AND [name] = @ExtendedPropertyName;' +

	--Variables
	+ N'DECLARE @objectid INT, 
		@TrigObjectId INT, 
		@CheckConstObjectId INT, 
		@DefaultConstObjectId INT;';

	/***********************
	Generate markdown for tables
	************************/
	--Build table of contents 
	SET @Sql = @Sql + N'
	IF EXISTS (SELECT 1 FROM [sys].[all_objects] WHERE [type] = ''U'' AND [is_ms_shipped] = 0)
	BEGIN
		INSERT INTO #markdown (value)
		VALUES (CONCAT(CHAR(13), CHAR(10), ''## Tables''))
			,(CONCAT(CHAR(13), CHAR(10), ''<details><summary>Click to expand</summary>'', CHAR(13), CHAR(10)));
	END;' +

	+ N'INSERT INTO #markdown (value)
	SELECT CONCAT(''* ['', OBJECT_SCHEMA_NAME(object_id), ''.'', OBJECT_NAME(object_id), ''](#'', LOWER(OBJECT_SCHEMA_NAME(object_id)), LOWER(OBJECT_NAME(object_id)), '')'')
	FROM [sys].[all_objects]
	WHERE [type] = ''U''
		AND [is_ms_shipped] = 0
	ORDER BY OBJECT_SCHEMA_NAME([object_id]), [name] ASC;' +

	--Object details
	+ N'DECLARE Obj_Cursor CURSOR 
	  LOCAL STATIC READ_ONLY FORWARD_ONLY
	FOR 
	SELECT [object_id]
	FROM [sys].[tables]
	WHERE [type] = ''U''
	ORDER BY OBJECT_SCHEMA_NAME([object_id]), [name] ASC;

	OPEN Obj_Cursor
	FETCH NEXT FROM Obj_Cursor INTO @objectid
	WHILE @@FETCH_STATUS = 0
	BEGIN 

		INSERT INTO #markdown
		SELECT CONCAT(CHAR(13), CHAR(10), ''### '', OBJECT_SCHEMA_NAME(@objectid), ''.'', OBJECT_NAME(@objectid));' +

		--Extended Properties
		+ N'INSERT INTO #markdown
		SELECT CONCAT(CHAR(13), CHAR(10), CAST([ep].[value] AS VARCHAR(8000)))
		FROM [sys].[all_objects] AS [o] 
			INNER JOIN [sys].[extended_properties] AS [ep] ON [o].[object_id] = [ep].[major_id]
		WHERE [o].[object_id] = @objectid
			AND [ep].[minor_id] = 0 --On the table

		INSERT INTO #markdown (value)
		VALUES ('''')
			,(CONCAT(''| Column | Type | Null | Foreign Key | Default | '', @ExtendedPropertyName COLLATE DATABASE_DEFAULT, '' |''))
			,(''| --- | ---| --- | --- | --- | --- |'');' +

		--Columns
		+ N'INSERT INTO #markdown
		SELECT CONCAT('' | '', ISNULL([c].[name], ''N/A'') 
				,'' | ''
				,CONCAT(UPPER(type_name(user_type_id)), 
					CASE 
						WHEN TYPE_NAME(user_type_id) IN (N''decimal'',N''numeric'') 
						THEN CONCAT(N''('',CAST([c].precision AS varchar(5)), N'','',CAST([c].scale AS varchar(5)), N'')'')
						WHEN TYPE_NAME(user_type_id) IN (''varchar'', ''char'')
						THEN CAST(max_length AS VARCHAR(10))
						WHEN TYPE_NAME(user_type_id) IN (N''time'',N''datetime2'',N''datetimeoffset'') 
						THEN CONCAT(N''('',CAST([c].scale AS varchar(5)), N'')'')
						WHEN TYPE_NAME([c].user_type_id) in (N''float'')
						THEN CASE WHEN [c].precision = 53 THEN N'''' ELSE CONCAT(N''('',CAST([c].precision AS varchar(5)),N'')'') END
						WHEN TYPE_NAME([c].user_type_id) IN (N''int'',N''bigint'',N''smallint'',N''tinyint'',N''money'',N''smallmoney'',
							N''real'',N''datetime'',N''smalldatetime'',N''bit'',N''image'',N''text'',N''uniqueidentifier'',
							N''date'',N''ntext'',N''sql_variant'',N''hierarchyid'',''geography'',N''timestamp'',N''xml'') 
						THEN N''''
						ELSE CONCAT(N''('',CASE 
											WHEN [c].max_length = -1 
											THEN N''MAX'' 
											WHEN TYPE_NAME([c].user_type_id) IN (N''nvarchar'',N''nchar'') 
											THEN CAST([c].[max_length]/2 AS VARCHAR(10))
											ELSE CAST([c].max_length AS VARCHAR(10))
											END, N'')'')
					END)
				,'' | ''
				,CASE [c].[is_nullable]
					WHEN 1
					THEN ''yes''
					ELSE ''no''
					END
				,'' | ''
				,CASE 
					WHEN [fk].[parent_object_id] IS NULL
					THEN ''''
					ELSE CONCAT(''['',OBJECT_SCHEMA_NAME([fk].[referenced_object_id]), ''.'', OBJECT_NAME([fk].[referenced_object_id]), ''.'', COL_NAME([fk].[referenced_object_id], [fk].[referenced_column_id]),'']'',''(#'',LOWER(OBJECT_SCHEMA_NAME([fk].[referenced_object_id])), LOWER(OBJECT_NAME([fk].[referenced_object_id])), '')'')
					END
				,'' | ''
				,OBJECT_DEFINITION([dc].[object_id])
				,'' | ''
				,CAST([ep].[value] AS VARCHAR(8000))
				,'' |'')
		FROM [sys].[all_objects] AS [o] 
			INNER JOIN [sys].[columns] AS [c] ON [o].[object_id] = [c].[object_id]
			LEFT JOIN [sys].[extended_properties] AS [ep] ON [o].[object_id] = [ep].[major_id]
				AND [ep].[minor_id] > 0
				AND [ep].[minor_id] = [c].[column_id]
				AND [ep].[class] = 1 --Object/col
				AND [ep].[name] = @ExtendedPropertyName
			LEFT JOIN [sys].[foreign_key_columns] AS [fk] ON [fk].[parent_object_id] = [c].[object_id]
				AND [fk].[parent_column_id] = [c].[column_id]
			LEFT JOIN [sys].[default_constraints] [dc] ON [dc].[parent_object_id] = [c].[object_id]
				AND [dc].[parent_column_id] = [c].[column_id]
		WHERE [o].[object_id] = @objectid;' +

		--Triggers
		+ N'IF EXISTS (SELECT * FROM [sys].[triggers] WHERE [parent_id] = @objectid)
		BEGIN
			INSERT INTO #markdown
			SELECT CONCAT(''#### '', ''Triggers'')
			DECLARE Trig_Cursor CURSOR
			LOCAL STATIC READ_ONLY FORWARD_ONLY
			FOR
			SELECT [object_id]
			FROM [sys].[triggers]
			WHERE [parent_id] = @objectId
			ORDER BY OBJECT_SCHEMA_NAME([object_id]), [name] ASC;

			OPEN Trig_Cursor
			FETCH NEXT FROM Trig_Cursor INTO @TrigObjectId
			WHILE @@FETCH_STATUS = 0
			BEGIN ' +
				+ N'INSERT INTO #markdown
				VALUES (CONCAT(''##### '', OBJECT_SCHEMA_NAME(@TrigObjectId), ''.'', OBJECT_NAME(@TrigObjectId)))
					,(CONCAT(''###### '', ''Definition''))
					,(''<details><summary>Click to expand</summary>'')
					,('''');' +

				--Object definition
				+ N'INSERT INTO #markdown (value)
				VALUES (''```sql'')
						,(OBJECT_DEFINITION(@TrigObjectId))
						,(''```'')
						,('''');

				INSERT INTO #markdown
				VALUES (''</details>'')
					,('''');

				FETCH NEXT FROM Trig_Cursor INTO @TrigObjectId;
			END;

			CLOSE Trig_Cursor;
			DEALLOCATE Trig_Cursor;
		END;' +

		--Check Constraints
		+ N'IF EXISTS (SELECT *  FROM [sys].[check_constraints] WHERE [parent_object_id] = @objectid)
		BEGIN
			INSERT INTO #markdown
			SELECT CONCAT(CHAR(13), CHAR(10), ''#### '', ''Check Constraints'')
			DECLARE Check_Cursor CURSOR
			LOCAL STATIC READ_ONLY FORWARD_ONLY
			FOR
			SELECT [object_id]
			FROM [sys].[check_constraints]
			WHERE [parent_object_id] = @objectid
			ORDER BY OBJECT_SCHEMA_NAME(object_id), [name] ASC;

			OPEN Check_Cursor
			FETCH NEXT FROM Check_Cursor INTO @CheckConstObjectId
			WHILE @@FETCH_STATUS = 0
			BEGIN ' +
				+ N'INSERT INTO #markdown
				VALUES (CONCAT(CHAR(13), CHAR(10),''##### '', OBJECT_SCHEMA_NAME(@CheckConstObjectId), ''.'', OBJECT_NAME(@CheckConstObjectId)))
					,(CONCAT(CHAR(13), CHAR(10),''###### '', ''Definition''))
					,(CONCAT(CHAR(13), CHAR(10),''<details><summary>Click to expand</summary>'', CHAR(13), CHAR(10)));' +

				--Object definition
				+ N'INSERT INTO #markdown (value)
				VALUES (''```sql'')
						,(OBJECT_DEFINITION(@CheckConstObjectId))
						,(''```'')
						,('''');

				INSERT INTO #markdown
				VALUES (''</details>'');

				FETCH NEXT FROM Check_Cursor INTO @CheckConstObjectId;
			END;

			CLOSE Check_Cursor;
			DEALLOCATE Check_Cursor;
		END;' +

		--Back to top
		+ N'INSERT INTO #markdown
		VALUES (CONCAT(CHAR(13), CHAR(10), ''[Back to top](#'', LOWER(@DatabaseName COLLATE DATABASE_DEFAULT), '')''))

		FETCH NEXT FROM Obj_Cursor INTO @objectid;

	END;
	CLOSE Obj_Cursor;
	DEALLOCATE Obj_Cursor;' +

	--End collapsible table section
	+ N'INSERT INTO #markdown
	VALUES (CONCAT(CHAR(13), CHAR(10), ''</details>''));';

	--End markdown for tables

	/***********************
	Generate markdown for views
	************************/
	--Build table of contents
	SET @Sql = @Sql + N'
	IF EXISTS (SELECT 1 FROM [sys].[views] WHERE [is_ms_shipped] = 0)
	BEGIN;
		INSERT INTO #markdown (value)
		VALUES (CONCAT(CHAR(13), CHAR(10), ''## Views'')) ,(CONCAT(CHAR(13), CHAR(10), ''<details><summary>Click to expand</summary>'', CHAR(13), CHAR(10)));
	END;' +

	+ N'INSERT INTO #markdown (value)
	SELECT CONCAT(''* ['', OBJECT_SCHEMA_NAME(object_id), ''.'', OBJECT_NAME(object_id), ''](#'', LOWER(OBJECT_SCHEMA_NAME(object_id)), LOWER(OBJECT_NAME(object_id)), '')'')
	FROM [sys].[views]
	WHERE [is_ms_shipped] = 0
	ORDER BY OBJECT_SCHEMA_NAME([object_id]), [name] ASC;' +

	--Object details
	+ N'DECLARE Obj_Cursor CURSOR 
	  LOCAL STATIC READ_ONLY FORWARD_ONLY
	FOR 
	SELECT [object_id]
	FROM [sys].[views]
	WHERE [is_ms_shipped] = 0
	ORDER BY OBJECT_SCHEMA_NAME([object_id]), [name] ASC;

	OPEN Obj_Cursor
	FETCH NEXT FROM Obj_Cursor INTO @objectid
	WHILE @@FETCH_STATUS = 0
	BEGIN 

		INSERT INTO #markdown
		SELECT CONCAT(CHAR(13), CHAR(10), ''### '', OBJECT_SCHEMA_NAME(@objectid), ''.'', OBJECT_NAME(@objectid));' +

		--Extended Properties
		+ N'INSERT INTO #markdown
		SELECT CAST([ep].[value] AS VARCHAR(8000))
		FROM [sys].[all_objects] AS [o] 
			INNER JOIN [sys].[extended_properties] AS [ep] ON [o].[object_id] = [ep].[major_id]
		WHERE [o].[object_id] = @objectid
			AND [ep].[minor_id] = 0

		INSERT INTO #markdown (value)
		VALUES ('''')
				,(CONCAT(''| Column | Type | Null | '', @ExtendedPropertyName COLLATE DATABASE_DEFAULT, '' |''))
				,(''| --- | ---| --- | --- |'');' +

		--Projected columns
		+ N'INSERT INTO #markdown
		SELECT CONCAT([c].[name]
				,'' | ''
				,CONCAT(UPPER(type_name(user_type_id)), 
					CASE 
						WHEN TYPE_NAME(user_type_id) IN (N''decimal'',N''numeric'') 
						THEN CONCAT(N''('',CAST([c].precision AS varchar(5)), N'','',CAST([c].scale AS varchar(5)), N'')'')
						WHEN TYPE_NAME(user_type_id) IN (''varchar'', ''char'')
						THEN CAST(max_length AS VARCHAR(10))
						WHEN TYPE_NAME(user_type_id) IN (N''time'',N''datetime2'',N''datetimeoffset'') 
						THEN CONCAT(N''('',CAST([c].scale AS varchar(5)), N'')'')
						WHEN TYPE_NAME([c].user_type_id) in (N''float'')
						THEN CASE WHEN [c].precision = 53 THEN N'''' ELSE CONCAT(N''('',CAST([c].precision AS varchar(5)),N'')'') END
						WHEN TYPE_NAME([c].user_type_id) IN (N''int'',N''bigint'',N''smallint'',N''tinyint'',N''money'',N''smallmoney'',
							N''real'',N''datetime'',N''smalldatetime'',N''bit'',N''image'',N''text'',N''uniqueidentifier'',N''date'',
							N''ntext'',N''sql_variant'',N''hierarchyid'',''geography'',N''timestamp'',N''xml'') 
						THEN N''''
						ELSE CONCAT(N''('',CASE 
											WHEN [c].max_length = -1 
											THEN N''MAX'' 
											WHEN TYPE_NAME([c].user_type_id) IN (N''nvarchar'',N''nchar'') 
											THEN CAST([c].[max_length]/2 AS VARCHAR(10))
											ELSE CAST([c].max_length AS VARCHAR(10))
											END, N'')'')
					END)
				,'' | ''
				,CASE [c].[is_nullable]
					WHEN 1
					THEN ''yes''
					ELSE ''no''
					END
				,'' | ''
				,CAST([ep].[value] AS VARCHAR(8000))
				,'' |'')
		FROM [sys].[views] AS [o]
			INNER JOIN [sys].[columns] AS [c] ON [o].[object_id] = [c].[object_id]
			LEFT JOIN [sys].[extended_properties] AS [ep] ON [o].[object_id] = [ep].[major_id]
				AND [ep].[minor_id] = [c].[column_id]
				AND [ep].[name] = @ExtendedPropertyName
		WHERE [o].[is_ms_shipped] = 0	-- User objects only
			AND [o].[type] = ''V''		-- VIEW
			AND [o].[object_id] = @objectid
		ORDER BY SCHEMA_NAME([o].[schema_id]), [o].[type_desc], OBJECT_NAME([ep].major_id);

		INSERT INTO #markdown (value)
		VALUES(CONCAT(CHAR(13), CHAR(10), ''#### Definition''))
			,(CONCAT(CHAR(13), CHAR(10), ''<details><summary>Click to expand</summary>'', CHAR(13), CHAR(10)));' +

		--Object definition
		+ N'INSERT INTO #markdown (value)
		VALUES (CONCAT(''```sql'', (OBJECT_DEFINITION(@objectid))))
				,(''```'');' +

		--Back to top
		+ N'INSERT INTO #markdown
		VALUES (CONCAT(CHAR(13), CHAR(10), ''</details>''))
			,(CONCAT(CHAR(13), CHAR(10), ''[Back to top](#'', LOWER(@DatabaseName COLLATE DATABASE_DEFAULT), '')''));

		FETCH NEXT FROM Obj_Cursor INTO @objectid;

	END;
	CLOSE Obj_Cursor;
	DEALLOCATE Obj_Cursor;' +

	--End collapsible view section
	+ N'INSERT INTO #markdown
	VALUES (CONCAT(CHAR(13), CHAR(10), ''</details>''));';

	--End markdown for views

	/***********************
	Generate markdown for procedures
	************************/
	--Build table of contents
	SET @Sql = @Sql + N'
	IF EXISTS (SELECT 1 FROM [sys].[procedures] WHERE [is_ms_shipped] = 0)
	BEGIN;
		INSERT INTO #markdown
		VALUES (CONCAT(CHAR(13), CHAR(10), ''## Stored Procedures'')) ,(CONCAT(CHAR(13), CHAR(10), ''<details><summary>Click to expand</summary>'', CHAR(13), CHAR(10)));
	END;' +

	+ N'INSERT INTO #markdown
	SELECT CONCAT(''* ['', OBJECT_SCHEMA_NAME([object_id]), ''.'', OBJECT_NAME([object_id]), ''](#'', LOWER(OBJECT_SCHEMA_NAME([object_id])), LOWER(OBJECT_NAME([object_id])), '')'')
	FROM [sys].[procedures]
	WHERE [is_ms_shipped] = 0
	ORDER BY OBJECT_SCHEMA_NAME(object_id), [name] ASC;' +

	--Object details
	+ N'DECLARE Obj_Cursor CURSOR 
	  LOCAL STATIC READ_ONLY FORWARD_ONLY
	FOR 
	SELECT [object_id]
	FROM [sys].[procedures]
	WHERE [is_ms_shipped] = 0
	ORDER BY OBJECT_SCHEMA_NAME([object_id]), [name] ASC;

	OPEN Obj_Cursor
	FETCH NEXT FROM Obj_Cursor INTO @objectid
	WHILE @@FETCH_STATUS = 0
	BEGIN 

		INSERT INTO #markdown
		SELECT CONCAT(CHAR(13), CHAR(10), ''### '', OBJECT_SCHEMA_NAME(@objectid), ''.'', OBJECT_NAME(@objectid));' +

		--Extended properties
		+ N'INSERT INTO #markdown
		SELECT CAST([ep].[value] AS VARCHAR(8000))
		FROM [sys].[all_objects] AS [o] 
			INNER JOIN [sys].[extended_properties] AS [ep] ON [o].[object_id] = [ep].[major_id]
		WHERE [o].[object_id] = @objectid
			AND [ep].[minor_id] = 0;' +

		--Check for parameters
		+ N'IF EXISTS (SELECT * FROM [sys].[parameters] AS [param] WHERE [param].[object_id] = @objectid)
		BEGIN
			INSERT INTO #markdown (value)
			VALUES (CONCAT(CHAR(13), CHAR(10), ''| Parameter | Type | Output |''))
					,(''| --- | --- | --- |'');

			INSERT INTO #markdown
			select CONCAT(CASE WHEN LEN([param].[name]) = 0 THEN ''*Output*'' ELSE [param].[name] END
					,'' | ''
					,CONCAT(UPPER(type_name(user_type_id)), 
					CASE 
						WHEN TYPE_NAME(user_type_id) IN (N''decimal'',N''numeric'') 
						THEN CONCAT(N''('',CAST(precision AS varchar(5)), N'','',CAST(scale AS varchar(5)), N'')'')
						WHEN TYPE_NAME(user_type_id) IN (''varchar'', ''char'')
						THEN CAST(max_length AS VARCHAR(10))
						WHEN TYPE_NAME(user_type_id) IN (N''time'',N''datetime2'',N''datetimeoffset'') 
						THEN CONCAT(N''('',CAST(scale AS varchar(5)), N'')'')
						WHEN TYPE_NAME(user_type_id) in (N''float'')
						THEN CASE WHEN precision = 53 THEN N'''' ELSE CONCAT(N''('',CAST(precision AS varchar(5)),N'')'') END
						WHEN TYPE_NAME(user_type_id) IN (N''int'',N''bigint'',N''smallint'',N''tinyint'',N''money'',N''smallmoney'',
							N''real'',N''datetime'',N''smalldatetime'',N''bit'',N''image'',N''text'',N''uniqueidentifier'',
							N''date'',N''ntext'',N''sql_variant'',N''hierarchyid'',''geography'',N''timestamp'',N''xml'') 
						THEN N''''
						ELSE CONCAT(N''('',CASE 
											WHEN max_length = -1 
											THEN N''MAX'' 
											WHEN TYPE_NAME(user_type_id) IN (N''nvarchar'',N''nchar'') 
											THEN CAST([max_length]/2 AS VARCHAR(10))
											ELSE CAST(max_length AS VARCHAR(10))
											END, N'')'')
					END)
					,'' | ''
					,CASE [is_output]
						WHEN 1
						THEN ''yes''
						ELSE ''no''
						END
					,'' |'')
			  FROM [sys].[procedures] AS [proc]
				INNER JOIN [sys].[parameters] AS [param] ON [param].[object_id] = [proc].[object_id]
			  WHERE [proc].[object_id] = @objectid
			  ORDER BY [param].[parameter_id] ASC;
		END

		INSERT INTO #markdown (value)
		VALUES(CONCAT(CHAR(13), CHAR(10), ''#### Definition''))
			,(CONCAT(CHAR(13), CHAR(10), ''<details><summary>Click to expand</summary>''));' +

		--Object definition
		+ N'INSERT INTO #markdown (value)
		VALUES (CONCAT(CHAR(13), CHAR(10), ''```sql'', 
			CHAR(13), CHAR(10), OBJECT_DEFINITION(@objectid)))
			,(''```'');' +

		--Back to top
		+ N'INSERT INTO #markdown
		VALUES (CONCAT(CHAR(13), CHAR(10), ''</details>''))
			,(CONCAT(CHAR(13), CHAR(10), ''[Back to top](#'', LOWER(@DatabaseName COLLATE DATABASE_DEFAULT), '')''));

		FETCH NEXT FROM Obj_Cursor INTO @objectid

	END;
	CLOSE Obj_Cursor;
	DEALLOCATE Obj_Cursor;' +

	--End collapsible stored procedure section
	+ N'INSERT INTO #markdown
	VALUES (CONCAT(CHAR(13), CHAR(10), ''</details>''));';

	--End markdown for stored procedures

	/***********************
	Generate markdown for scalar functions
	************************/
	--Build table of contents
	SET @Sql = @Sql + N'
	IF EXISTS (SELECT 1 FROM [sys].[objects] WHERE [is_ms_shipped] = 0 AND [type] = ''FN'')
	BEGIN;
		INSERT INTO #markdown (value)
		VALUES (CONCAT(CHAR(13), CHAR(10), ''## Scalar Functions'')) ,(CONCAT(CHAR(13), CHAR(10), ''<details><summary>Click to expand</summary>'', CHAR(13), CHAR(10)));
	END;' +

	+ N'INSERT INTO #markdown
	SELECT CONCAT(''* ['', OBJECT_SCHEMA_NAME(object_id), ''.'', OBJECT_NAME(object_id), ''](#'', LOWER(OBJECT_SCHEMA_NAME(object_id)), LOWER(OBJECT_NAME(object_id)), '')'')
	FROM [sys].[objects]
	WHERE [is_ms_shipped] = 0
		AND [type] = ''FN'' --SQL_SCALAR_FUNCTION
	ORDER BY OBJECT_SCHEMA_NAME([object_id]), [name] ASC;' +

	--Object details
	+ N'DECLARE Obj_Cursor CURSOR 
	  LOCAL STATIC READ_ONLY FORWARD_ONLY
	FOR 
	SELECT [object_id]
	FROM [sys].[objects]
	WHERE [is_ms_shipped] = 0
		AND [type] = ''FN'' --SQL_SCALAR_FUNCTION
	ORDER BY OBJECT_SCHEMA_NAME([object_id]), [name] ASC;

	OPEN Obj_Cursor
	FETCH NEXT FROM Obj_Cursor INTO @objectid
	WHILE @@FETCH_STATUS = 0
	BEGIN

		INSERT INTO #markdown
		SELECT CONCAT(CHAR(13), CHAR(10), ''### '', OBJECT_SCHEMA_NAME(@objectid), ''.'', OBJECT_NAME(@objectid));' +

		--Extended properties
		+ N'INSERT INTO #markdown
		SELECT CAST([ep].[value] AS VARCHAR(8000))
		FROM [sys].[all_objects] AS [o] 
			INNER JOIN [sys].[extended_properties] AS [ep] ON [o].[object_id] = [ep].[major_id]
		WHERE [o].[object_id] = @objectid
			AND [ep].[minor_id] = 0;' +

		--Check for parameters
		+ N'IF EXISTS (SELECT * FROM [sys].[parameters] AS [param] WHERE [param].[object_id] = @objectid)
		BEGIN
			INSERT INTO #markdown (value)
			VALUES ('''')
					,(''| Parameter | Type | Output'')
					,(''| --- | --- | --- |'');

			INSERT INTO #markdown
			select CONCAT(CASE WHEN LEN([param].[name]) = 0 THEN ''*Output*'' ELSE [param].[name] END
					,'' | ''
					,CONCAT(UPPER(type_name(user_type_id)), 
					CASE 
						WHEN TYPE_NAME(user_type_id) IN (N''decimal'',N''numeric'') 
						THEN CONCAT(N''('',CAST(precision AS varchar(5)), N'','',CAST(scale AS varchar(5)), N'')'')
						WHEN TYPE_NAME(user_type_id) IN (''varchar'', ''char'')
						THEN CAST(max_length AS VARCHAR(10))
						WHEN TYPE_NAME(user_type_id) IN (N''time'',N''datetime2'',N''datetimeoffset'') 
						THEN CONCAT(N''('',CAST(scale AS varchar(5)), N'')'')
						WHEN TYPE_NAME(user_type_id) in (N''float'')
						THEN CASE WHEN precision = 53 THEN N'''' ELSE CONCAT(N''('',CAST(precision AS varchar(5)),N'')'') END
						WHEN TYPE_NAME(user_type_id) IN (N''int'',N''bigint'',N''smallint'',N''tinyint'',N''money'',N''smallmoney'',
							N''real'',N''datetime'',N''smalldatetime'',N''bit'',N''image'',N''text'',N''uniqueidentifier'',
							N''date'',N''ntext'',N''sql_variant'',N''hierarchyid'',''geography'',N''timestamp'',N''xml'') 
						THEN N''''
						ELSE CONCAT(N''('',CASE 
											WHEN max_length = -1 
											THEN N''MAX'' 
											WHEN TYPE_NAME(user_type_id) IN (N''nvarchar'',N''nchar'') 
											THEN CAST([max_length]/2 AS VARCHAR(10))
											ELSE CAST(max_length AS VARCHAR(10))
											END, N'')'')
					END)
					,'' | ''
					,CASE [is_output]
						WHEN 1
						THEN ''yes''
						ELSE ''no''
						END
					,'' |'')
			  FROM [sys].[objects] AS [o]
				INNER JOIN [sys].[parameters] AS [param] ON [param].[object_id] = [o].[object_id]
			  WHERE [o].[object_id] = @objectid
			  ORDER BY [param].[parameter_id] ASC;
		END;

		INSERT INTO #markdown (value)
		VALUES(CONCAT(CHAR(13), CHAR(10), ''#### Definition''))
			,(CONCAT(CHAR(13), CHAR(10), ''<details><summary>Click to expand</summary>''));' +

		--Object definition
		+ N'INSERT INTO #markdown (value)
		VALUES (CONCAT(CHAR(13), CHAR(10), ''```sql'',
			CHAR(13), CHAR(10), OBJECT_DEFINITION(@objectid)))
				,(''```'');' +

		--Back to top
		+ N'INSERT INTO #markdown
		VALUES (CONCAT(CHAR(13), CHAR(10), ''</details>''))
			,(CONCAT(CHAR(13), CHAR(10), ''[Back to top](#'', LOWER(@DatabaseName COLLATE DATABASE_DEFAULT), '')''));

		FETCH NEXT FROM Obj_Cursor INTO @objectid;

	END;
	CLOSE Obj_Cursor;
	DEALLOCATE Obj_Cursor;' +

	--End collapsible scalar functions section
	+ N'INSERT INTO #markdown
	VALUES (CONCAT(CHAR(13), CHAR(10), ''</details>''));';

	--End markdown for scalar functions

	/***********************
	Generate markdown for table functions
	************************/
	--Build table of contents
	SET @Sql = @Sql + N'
	IF EXISTS (SELECT 1 FROM [sys].[objects] WHERE [is_ms_shipped] = 0 AND [type] = ''IF'')
	BEGIN;
		INSERT INTO #markdown
		VALUES (CONCAT(CHAR(13), CHAR(10), ''## Table Functions'')) ,(CONCAT(CHAR(13), CHAR(10), ''<details><summary>Click to expand</summary>'', CHAR(13), CHAR(10)));
	END;' +

	+ N'INSERT INTO #markdown
	SELECT CONCAT(''* ['', OBJECT_SCHEMA_NAME(object_id), ''.'', OBJECT_NAME(object_id), ''](#'', LOWER(OBJECT_SCHEMA_NAME(object_id)), LOWER(OBJECT_NAME(object_id)), '')'')
	FROM [sys].[objects]
	WHERE [is_ms_shipped] = 0
		AND [type] = ''IF'' --SQL_INLINE_TABLE_VALUED_FUNCTION
	ORDER BY OBJECT_SCHEMA_NAME(object_id), [name] ASC;' +

	--Object details
	+ N'DECLARE Obj_Cursor CURSOR 
	  LOCAL STATIC READ_ONLY FORWARD_ONLY
	FOR 
	SELECT [object_id]
	FROM [sys].[objects]
	WHERE [is_ms_shipped] = 0
		AND [type] = ''IF'' --SQL_INLINE_TABLE_VALUED_FUNCTION
	ORDER BY OBJECT_SCHEMA_NAME([object_id]), [name] ASC;

	OPEN Obj_Cursor
	FETCH NEXT FROM Obj_Cursor INTO @objectid
	WHILE @@FETCH_STATUS = 0
	BEGIN

		INSERT INTO #markdown
		SELECT CONCAT(CHAR(13), CHAR(10), ''### '', OBJECT_SCHEMA_NAME(@objectid), ''.'', OBJECT_NAME(@objectid));' +

		--Extended properties
		+ N'INSERT INTO #markdown
		SELECT CAST([ep].[value] AS VARCHAR(8000))
		FROM [sys].[all_objects] AS [o] 
			INNER JOIN [sys].[extended_properties] AS [ep] ON [o].[object_id] = [ep].[major_id]
		WHERE [o].[object_id] = @objectid
			AND [ep].[minor_id] = 0;' +

		--Check for parameters
		+ N'IF EXISTS (SELECT * FROM [sys].[parameters] AS [param] WHERE [param].[object_id] = @objectid)
		BEGIN
			INSERT INTO #markdown (value)
			VALUES (CONCAT(CHAR(13), CHAR(10), ''| Parameter | Type | Output |''))
					,(''| --- | --- | --- |'');

			INSERT INTO #markdown
			select CONCAT(CASE WHEN LEN([param].[name]) = 0 THEN ''*Output*'' ELSE [param].[name] END
					,'' | ''
					,CONCAT(UPPER(type_name(user_type_id)), 
					CASE 
						WHEN TYPE_NAME(user_type_id) IN (N''decimal'',N''numeric'') 
						THEN CONCAT(N''('',CAST(precision AS varchar(5)), N'','',CAST(scale AS varchar(5)), N'')'')
						WHEN TYPE_NAME(user_type_id) IN (''varchar'', ''char'')
						THEN CAST(max_length AS VARCHAR(10))
						WHEN TYPE_NAME(user_type_id) IN (N''time'',N''datetime2'',N''datetimeoffset'') 
						THEN CONCAT(N''('',CAST(scale AS varchar(5)), N'')'')
						WHEN TYPE_NAME(user_type_id) in (N''float'')
						THEN CASE WHEN precision = 53 THEN N'''' ELSE CONCAT(N''('',CAST(precision AS varchar(5)),N'')'') END
						WHEN TYPE_NAME(user_type_id) IN (N''int'',N''bigint'',N''smallint'',N''tinyint'',N''money'',N''smallmoney'',N''real'',N''datetime'',N''smalldatetime'',N''bit'',N''image'',N''text'',N''uniqueidentifier'',N''date'',N''ntext'',N''sql_variant'',N''hierarchyid'',''geography'',N''timestamp'',N''xml'') 
						THEN N''''
						ELSE CONCAT(N''('',CASE 
											WHEN max_length = -1 
											THEN N''MAX'' 
											WHEN TYPE_NAME(user_type_id) IN (N''nvarchar'',N''nchar'') 
											THEN CAST([max_length]/2 AS VARCHAR(10))
											ELSE CAST(max_length AS VARCHAR(10))
											END, N'')'')
					END)
					,'' | ''
					,CASE [is_output]
						WHEN 1
						THEN ''yes''
						ELSE ''no''
						END
					,'' |'')
			  FROM [sys].[objects] AS [o]
				INNER JOIN [sys].[parameters] AS [param] ON [param].[object_id] = [o].[object_id]
			  WHERE [o].[object_id] = @objectid
			  ORDER BY [param].[parameter_id] ASC;
		END;		
		
		INSERT INTO #markdown (value)
		VALUES(CONCAT(CHAR(13), CHAR(10), ''#### Definition''))
			,(CONCAT(CHAR(13), CHAR(10), ''<details><summary>Click to expand</summary>''));' +

		--Object definition
		+ N'INSERT INTO #markdown (value)
		VALUES (CONCAT(CHAR(13), CHAR(10), ''```sql'',
			CHAR(13), CHAR(10), OBJECT_DEFINITION(@objectid)))
				,(''```'');' +

		--Back to top
		+ N'INSERT INTO #markdown
		VALUES (CONCAT(CHAR(13), CHAR(10), ''</details>''))
			,(CONCAT(CHAR(13), CHAR(10),''[Back to top](#'', LOWER(@DatabaseName COLLATE DATABASE_DEFAULT), '')''));

		FETCH NEXT FROM Obj_Cursor INTO @objectid;

	END;
	CLOSE Obj_Cursor;
	DEALLOCATE Obj_Cursor;' +

	--End collapsible table functions section
	+ N'INSERT INTO #markdown
	VALUES (CONCAT(CHAR(13), CHAR(10), ''</details>''));';

	--End markdown for table functions

	/***********************
	Generate markdown for synonyms
	************************/
	--Build table of contents
	SET @Sql = @Sql + N'
	IF EXISTS (SELECT 1 FROM [sys].[synonyms] WHERE [is_ms_shipped] = 0)
	BEGIN;
		INSERT INTO #markdown ([value])
		VALUES (CONCAT(CHAR(13), CHAR(10), ''## Synonyms'')) ,(CONCAT(CHAR(13), CHAR(10), ''<details><summary>Click to expand</summary>''));
	END;' +

	+ N'INSERT INTO #markdown
	SELECT CONCAT(''* ['', OBJECT_SCHEMA_NAME([object_id]), ''.'', OBJECT_NAME([object_id]), ''](#'', LOWER(OBJECT_SCHEMA_NAME([object_id])), LOWER(OBJECT_NAME([object_id])), '')'')
	FROM [sys].[synonyms]
	WHERE [is_ms_shipped] = 0
	ORDER BY OBJECT_SCHEMA_NAME([object_id]), [name] ASC;' +

	--Object details
	+ N'DECLARE Obj_Cursor CURSOR 
	  LOCAL STATIC READ_ONLY FORWARD_ONLY
	FOR
	SELECT [object_id]
	FROM [sys].[synonyms]
	WHERE [is_ms_shipped] = 0
	ORDER BY OBJECT_SCHEMA_NAME([object_id]), [name] ASC;

	OPEN Obj_Cursor
	FETCH NEXT FROM Obj_Cursor INTO @objectid
	WHILE @@FETCH_STATUS = 0
	BEGIN 

		INSERT INTO #markdown
		SELECT CONCAT(CHAR(13), CHAR(10), ''### '', OBJECT_SCHEMA_NAME(@objectid), ''.'', OBJECT_NAME(@objectid), CHAR(13), CHAR(10)); ' +

		--Extended properties
		+ N'INSERT INTO #markdown
		SELECT CAST([ep].[value] AS VARCHAR(8000))
		FROM [sys].[all_objects] AS [o] 
			INNER JOIN [sys].[extended_properties] AS [ep] ON [o].[object_id] = [ep].[major_id]
		WHERE [o].[object_id] = @objectid
			AND [ep].[minor_id] = 0;

		INSERT INTO #markdown (value)
		VALUES (CONCAT(CHAR(13), CHAR(10), ''| Synonym | Base Object |''))
				,(''| --- | --- |'');' +

		--Object mapping
		+ N'INSERT INTO #markdown
		SELECT CONCAT(OBJECT_SCHEMA_NAME([syn].[object_id]), ''.'', OBJECT_NAME([syn].[object_id])
				,'' | ''
				,CASE WHEN PARSENAME([base_object_name], 3) = DB_NAME()
					THEN CONCAT(''['', PARSENAME([base_object_name], 3), ''.'', PARSENAME([base_object_name], 2), ''.'', PARSENAME([base_object_name], 1), '']'', ''(#'', PARSENAME([base_object_name], 2), ''.'', PARSENAME([base_object_name], 1), '')'')
					ELSE CONCAT(PARSENAME([base_object_name], 3), PARSENAME([base_object_name], 2), PARSENAME([base_object_name], 1))
				END
				,'' |'')
			FROM [sys].[synonyms] AS [syn]
			WHERE [syn].[object_id] = @objectid;' +

		--Back to top
		+ N'INSERT INTO #markdown
		VALUES (CONCAT(CHAR(13), CHAR(10),''[Back to top](#'', LOWER(@DatabaseName COLLATE DATABASE_DEFAULT), '')''));

		FETCH NEXT FROM Obj_Cursor INTO @objectid

	END
	CLOSE Obj_Cursor
	DEALLOCATE Obj_Cursor;' +

	--End collapsible synonyms section
	+ N'INSERT INTO #markdown
	VALUES (CONCAT(CHAR(13), CHAR(10), ''</details>''));'

	--End markdown for synonyms

	--Attribution
	+ N'INSERT INTO #markdown
	VALUES (CONCAT(CHAR(13), CHAR(10), ''----''))
		,(CONCAT(CHAR(13), CHAR(10), ''*Markdown generated by [sp_doc](https://expresssql.lowlydba.com/) ''))
		,(CONCAT(''at '', SYSDATETIMEOFFSET(), ''.*''));';

	--Return all data
	SET @Sql = @Sql + N'
	SELECT [value]
	FROM #markdown
	ORDER BY [ID] ASC;';

	SET @ParmDefinition = N'@ExtendedPropertyName SYSNAME, @DatabaseName SYSNAME';
	EXEC sp_executesql @Sql
		,@ParmDefinition
		,@ExtendedPropertyName
		,@DatabaseName;
END;
GO

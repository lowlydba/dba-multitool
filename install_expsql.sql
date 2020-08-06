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
	@DatabaseName SYSNAME               = NULL
	,@ExtendedPropertyName VARCHAR(100) = 'Description'
    /* Parameters defined here for testing only */
    ,@SqlMajorVersion TINYINT           = 0
    ,@SqlMinorVersion SMALLINT          = 0
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
	SELECT CONCAT(CHAR(13), CHAR(10), CAST([value] AS VARCHAR(200)))
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
	SET @Sql = @Sql + N'
	INSERT INTO #markdown (value)
	VALUES (CONCAT(CHAR(13), CHAR(10), ''## Tables''))
		,(CONCAT(CHAR(13), CHAR(10), ''<details><summary>Click to expand</summary>'', CHAR(13), CHAR(10)));' +

	--Build table of contents 
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
		SELECT CONCAT(CHAR(13), CHAR(10), CAST([ep].[value] AS VARCHAR(200)))
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
						WHEN TYPE_NAME([c].user_type_id) IN (N''int'',N''bigint'',N''smallint'',N''tinyint'',N''money'',N''smallmoney'',N''real'',N''datetime'',N''smalldatetime'',N''bit'',N''image'',N''text'',N''uniqueidentifier'',N''date'',N''ntext'',N''sql_variant'',N''hierarchyid'',''geography'',N''timestamp'',N''xml'') 
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
				,CAST([ep].[value] AS VARCHAR(200))
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
	SET @Sql = @Sql + N'
	INSERT INTO #markdown (value)
	VALUES (CONCAT(CHAR(13), CHAR(10), ''## Views''))
		,(CONCAT(CHAR(13), CHAR(10), ''<details><summary>Click to expand</summary>'', CHAR(13), CHAR(10)));' +

	--Build table of contents
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
		SELECT CAST([ep].[value] AS VARCHAR(200))
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
						WHEN TYPE_NAME([c].user_type_id) IN (N''int'',N''bigint'',N''smallint'',N''tinyint'',N''money'',N''smallmoney'',N''real'',N''datetime'',N''smalldatetime'',N''bit'',N''image'',N''text'',N''uniqueidentifier'',N''date'',N''ntext'',N''sql_variant'',N''hierarchyid'',''geography'',N''timestamp'',N''xml'') 
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
				,CAST([ep].[value] AS VARCHAR(200))
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
	SET @Sql = @Sql + N'
	INSERT INTO #markdown
	VALUES (CONCAT(CHAR(13), CHAR(10), ''## Stored Procedures''))
		,(CONCAT(CHAR(13), CHAR(10), ''<details><summary>Click to expand</summary>'', CHAR(13), CHAR(10)));' +

	--Build table of contents
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
		SELECT CAST([ep].[value] AS VARCHAR(200))
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
		VALUES (CONCAT(CHAR(13), CHAR(10), ''```sql'', OBJECT_DEFINITION(@objectid)))
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
	SET @Sql = @Sql + N'
	INSERT INTO #markdown (value)
	VALUES (CONCAT(CHAR(13), CHAR(10), ''## Scalar Functions''))
		,(CONCAT(CHAR(13), CHAR(10), ''<details><summary>Click to expand</summary>'', CHAR(13), CHAR(10)));' +

	--Build table of contents
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
		SELECT CAST([ep].[value] AS VARCHAR(200))
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
		VALUES (CONCAT(CHAR(13), CHAR(10), ''```sql'', OBJECT_DEFINITION(@objectid)))
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
	SET @Sql = @Sql + N'
	INSERT INTO #markdown
	VALUES (CONCAT(CHAR(13), CHAR(10), ''## Table Functions''))
		,(CONCAT(CHAR(13), CHAR(10), ''<details><summary>Click to expand</summary>'', CHAR(13), CHAR(10)));' +

	--Build table of contents
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
		SELECT CAST([ep].[value] AS VARCHAR(200))
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
		VALUES (CONCAT(CHAR(13), CHAR(10), ''```sql'', OBJECT_DEFINITION(@objectid)))
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
	SET @Sql = @Sql + N'
	INSERT INTO #markdown (value)
	VALUES (CONCAT(CHAR(13), CHAR(10), ''## Synonyms''))
		,(CONCAT(CHAR(13), CHAR(10), ''<details><summary>Click to expand</summary>''));' +

	--Build table of contents
	+ N'INSERT INTO #markdown
	SELECT CONCAT(''* ['', OBJECT_SCHEMA_NAME(object_id), ''.'', OBJECT_NAME(object_id), ''](#'', LOWER(OBJECT_SCHEMA_NAME(object_id)), LOWER(OBJECT_NAME(object_id)), '')'')
	FROM sys.synonyms
	WHERE is_ms_shipped = 0
	ORDER BY OBJECT_SCHEMA_NAME(object_id), [name] ASC;' +

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
		SELECT CAST([ep].[value] AS VARCHAR(200))
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
SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_helpme]') AND [type] IN (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[sp_helpme] AS';
END
GO

ALTER PROCEDURE [dbo].[sp_helpme]
	@objname SYSNAME = NULL
	,@epname SYSNAME = 'Description'
	/* Parameters defined here for testing only */
	,@SqlMajorVersion TINYINT = 0
	,@SqlMinorVersion SMALLINT = 0
AS

/*
sp_helpme - Part of the ExpressSQL Suite https://expresssql.lowlydba.com/

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
		,@ParmDefinition NVARCHAR(500)
		,@LastUpdated NVARCHAR(20) = '2020-06-29';

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
	IF 1 = (SELECT COUNT(*) FROM sys.all_columns AS ac WHERE ac.name = 'is_hidden' AND OBJECT_NAME(ac.object_id) = 'all_columns')
		BEGIN
			SET @HasHidden = 1;
		END;

	/* Check for Masked Columns feature */
	IF 1 = (SELECT COUNT(*) FROM sys.all_columns AS ac WHERE ac.name = 'is_masked' AND OBJECT_NAME(ac.object_id) = 'all_columns')
		BEGIN
			SET @HasMasked = 1;
		END;

	-- If no @objname given, give a little info about all objects.
	IF (@objname IS NULL)
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
					and [ep].[name] = @epname
					AND [ep].[minor_id] = 0
					AND [ep].[class] = 1 
			ORDER BY [Owner] ASC, [Object_type] DESC, [name] ASC;';
		SET @ParmDefinition = N'@epname SYSNAME';

		EXEC sp_executesql @SQLString
			,@ParmDefinition
			,@epname;

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

	-- Make sure the @objname is local to the current database.
	SELECT @ObjShortName = PARSENAME(@objname,1);
	SELECT @DbName = PARSENAME(@objname,3);
	IF @DbName IS NULL
		SELECT @DbName = DB_NAME();
	ELSE IF @DbName <> DB_NAME()
		BEGIN
			RAISERROR(15250,-1,-1);
		END

	-- @objname must be either sysobjects or systypes: first look in sysobjects
	SET @SQLString = N'SELECT @ObjID			= object_id
							, @SysObj_Type		= type 
						FROM sys.all_objects 
						WHERE object_id = OBJECT_ID(@objname);';  
	SET @ParmDefinition = N'@objname SYSNAME
						,@ObjID INT OUTPUT
						,@SysObj_Type VARCHAR(5) OUTPUT';

	EXEC sp_executesql @SQLString
		,@ParmDefinition
		,@objName
		,@ObjID OUTPUT
		,@SysObj_Type OUTPUT;

	-- If @objname not in sysobjects, try systypes
	IF @ObjID IS NULL
	BEGIN
		SET @SQLSTring = N'SELECT @ObjID = user_type_id
							FROM sys.types
							WHERE name = PARSENAME(@objname,1);';
		SET @ParmDefinition = N'@objname SYSNAME
							,@ObjID INT OUTPUT';
							
		EXEC sp_executesql @SQLString
			,@ParmDefinition
			,@objName
			,@ObjID OUTPUT;

		-- If not in systypes, return
		IF @ObjID IS NULL
		BEGIN
			RAISERROR(15009,-1,-1,@objname,@DbName);
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
							AND [ep].[name] = @epname
							AND [ep].[minor_id] = 0
							AND [ep].[class] = 6
					WHERE [user_type_id] = @ObjID';
		SET @ParmDefinition = N'@ObjID INT, @Yes VARCHAR(5), @No VARCHAR(5), @None VARCHAR(5), @epname SYSNAME';

		EXECUTE sp_executesql @SQLString
			,@ParmDefinition
			,@ObjID
			,@Yes
			,@No
			,@None
			,@epname;

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
			AND [ep].[name] = @epname
			AND [ep].[minor_id] = 0
			AND [ep].[class] = 1 
	WHERE [o].[object_id] = @ObjID;';

	SET @ParmDefinition = N'@ObjID INT, @epname SYSNAME';

	EXEC sp_executesql @SQLString
		,@ParmDefinition
		,@ObjID
		,@epname;

	-- Display column metadata if table / view
	SET @SQLString = N'
	IF EXISTS (select * from sys.all_columns where object_id = @ObjID)
	BEGIN;

		-- SET UP NUMERIC TYPES: THESE WILL HAVE NON-BLANK PREC/SCALE
		-- There must be a '','' immediately after each type name (including last one),
		-- because that''s what we''ll search for in charindex later.
		DECLARE @precscaletypes NVARCHAR(150);
		SELECT @precscaletypes = N''tinyint,smallint,decimal,int,bigint,real,money,float,numeric,smallmoney,date,time,datetime2,datetimeoffset,''

		-- INFO FOR EACH COLUMN
		select
			[Column_name]			= ac.name,
			[Type]					= type_name([ac].[user_type_id]),
			[Computed]				= case when ColumnProperty(object_id, [ac].[name], ''IsComputed'') = 0 then ''no'' else ''yes'' end,
			[Length]				= convert(int, [ac].[max_length]),
			-- for prec/scale, only show for those types that have valid precision/scale
			-- Search for type name + '','', because ''datetime'' is actually a substring of ''datetime2'' and ''datetimeoffset''
			[Prec]					= case when charindex(type_name([ac].[system_type_id]) + '','', '''') > 0
										then convert(char(5),ColumnProperty(object_id, ac.name, ''precision''))
										else ''     '' end,
			[Scale]					= case when charindex(type_name([ac].[system_type_id]) + '','', '''') > 0
										then convert(char(5),OdbcScale([ac].[system_type_id],[ac].[scale]))
										else ''     '' end,
			[Nullable]				= case when [ac].[is_nullable] = 0 then ''no'' else ''yes'' end, ';

			--Only include if they exist on the current version
			IF @HasMasked = 1
				BEGIN
					SET @SQLString = @SQLString +  N'[Masked] = case when is_masked = 0 then ''no'' else ''yes'' end, ';
				END
				
			SET @SQLString = @SQLString + N'[Sparse] = case when is_sparse = 0 then ''no'' else ''yes'' end, ';

			IF @HasHidden = 1
				BEGIN
					SET @SQLString = @SQLString +  N'[Hidden] = case when is_hidden = 0 then ''no'' else ''yes'' end, ';
				END
			
			SET @SQLString = @SQLString + N'
			[Identity]				= case when is_identity = 0 then ''no'' else ''yes'' end,
			[TrimTrailingBlanks]	= case ColumnProperty(object_id, ac.name, ''UsesAnsiTrim'')
										when 1 then ''no''
										when 0 then ''yes''
										else ''(n/a)'' end,
			[FixedLenNullInSource]	= case
										when type_name([ac].[system_type_id]) not in (''varbinary'',''varchar'',''binary'',''char'')
											then ''(n/a)''
										when [ac].[is_nullable] = 0 then ''no'' else ''yes'' end,
			[Collation]				= [ac].[collation_name],
			[ExtendedProperty]		= [ep].[value]
		FROM [sys].[all_columns] AS [ac]
			INNER JOIN [sys].[types] AS [typ] ON [typ].[system_type_id] = [ac].[system_type_id]
			LEFT JOIN sys.extended_properties ep ON ep.minor_id = ac.column_id
				AND ep.major_id = ac.[object_id]
				AND ep.[name] = @epname
				AND ep.class = 1
		WHERE [object_id] = @ObjID
	END';
	SET @ParmDefinition = N'@ObjID INT, @epname SYSNAME';  
	EXEC sp_executesql @SQLString, @ParmDefinition, @ObjID = @ObjID, @epname = @epname;

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
				'Seed'					= IDENT_SEED(@objname),
				'Increment'				= IDENT_INCR(@objname),
				'Not For Replication'	= COLUMNPROPERTY(@ObjID, @colname, 'IsIDNotForRepl');
		ELSE
			BEGIN
				SET @Msg = 'No identity is defined on object %ls.';
				RAISERROR(@Msg, 10, 1, @objname) WITH NOWAIT;
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
				RAISERROR(@Msg, 10, 1, @objname) WITH NOWAIT;
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
		EXEC sys.sp_helpindex @objname;
		EXEC sys.sp_helpconstraint @objname,'nomsg';

		SET @SQLString = N'SELECT @HasDepen = COUNT(*)
			FROM sys.objects obj, sysdepends deps
			WHERE obj.[type] =''V''
				AND obj.[object_id] = deps.id
				AND deps.depid = @ObjID
				AND deps.deptype = 1;';
		SET @ParmDefinition = N'@ObjID INT, @HasDepen INT OUTPUT';

		EXEC sp_executeSQL @SQLString
			,@ParmDefinition
			,@ObjID
			,@HasDepen OUTPUT;

		IF @HasDepen = 0
		BEGIN
			RAISERROR(15647,-1,-1,@objname); -- No views with schemabinding for reference table '%ls'.
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

	RETURN (0); -- sp_helpme
END;
GO
SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

/******************************/
/* Cleanup existing versions */
/*****************************/
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
sp_sizeoptimiser - Part of the ExpressSQL Suite https://expresssql.lowlydba.com/

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

	DECLARE @include SizeOptimiserTableType;

	INSERT INTO @include ([database_name])
	VALUES (N'WideWorldImporters');

	EXEC [dbo].[sp_sizeoptimiser] @IncludeDatabases = @include
	GO															
*/

BEGIN
	SET NOCOUNT ON;

	BEGIN TRY

		DECLARE @HasTempStat BIT = 0
			,@HasPersistedSamplePercent BIT	= 0
			,@CheckNumber TINYINT = 0
            ,@EngineEdition TINYINT
			,@LastUpdated NVARCHAR(20) = '2020-08-04'
			,@CheckSQL NVARCHAR(MAX) = N''
			,@Msg NVARCHAR(MAX)	= N''
			,@DbName SYSNAME = N''
			,@TempCheckSQL NVARCHAR(MAX) = N''
			,@Debug BIT	= 0;

		/* Validate @IndexNumThreshold */
		IF (@IndexNumThreshold < 1 OR @IndexNumThreshold > 999)
			BEGIN
				SET @Msg = '@IndexNumThreshold must be between 1 and 999.';
				RAISERROR(@Msg, 16, 1);
			END

		/* Validate database list */
		IF (SELECT COUNT(*) FROM @IncludeDatabases) >= 1 AND (SELECT COUNT(*) FROM @ExcludeDatabases) >= 1
			BEGIN
				SET @Msg = 'Both @IncludeDatabases and @ExcludeDatabases cannot be specified.';
				RAISERROR(@Msg, 16, 1);
			END

		CREATE TABLE #Databases (
			[database_name] SYSNAME NOT NULL);

		/* Build database list if no parameters set*/
		IF (SELECT COUNT(*) FROM @IncludeDatabases) = 0 AND (SELECT COUNT(*) FROM @ExcludeDatabases) = 0
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
		ELSE IF (SELECT COUNT(*) FROM @IncludeDatabases) >= 1
			BEGIN
				INSERT INTO #Databases
				SELECT [sd].[name]
				FROM @IncludeDatabases AS [d]
					INNER JOIN [sys].[databases] AS [sd] ON [sd].[name] COLLATE database_default = REPLACE(REPLACE([d].[database_name], '[', ''), ']', '')
				WHERE DATABASEPROPERTYEX([sd].[name], 'UPDATEABILITY') = N'READ_WRITE'
					AND DATABASEPROPERTYEX([sd].[name], 'USERACCESS') = N'MULTI_USER'
					AND DATABASEPROPERTYEX([sd].[name], 'STATUS') = N'ONLINE';

				IF (SELECT COUNT(*) FROM @IncludeDatabases) > (SELECT COUNT(*) FROM #Databases)
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
		ELSE IF (SELECT COUNT(*) FROM @ExcludeDatabases) >= 1
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

		/*Check for is_temp value on statistics*/
		IF 1 = (SELECT 1 FROM [sys].[all_columns] AS [ac] WHERE [ac].[name] = 'is_temporary' AND OBJECT_NAME([ac].[object_id]) = 'all_columns')
			 BEGIN;
				 SET @HasTempStat = 1;
			 END;

		/*Check for Persisted Sample Percent update */
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
				SET @Msg = CONCAT('Version: ', @LastUpdated);
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
				,N'http://expresssql.lowlydba.com/sp_sizeoptimiser.html';

		/* Date & Time Data Type Usage */
		SET @CheckNumber = @CheckNumber + 1;
		IF (@Verbose = 1)
			BEGIN;
				SET @Msg = CONCAT(N'Check ', @CheckNumber, ' - Date and Time Data Types');
				RAISERROR(@Msg, 10, 1) WITH NOWAIT;
			END;
		BEGIN;
			SET @CheckSQL = N'';
			SELECT @CheckSQL = @CheckSQL + N'USE ' + QUOTENAME([database_name]) + N';
								INSERT INTO #results ([check_num], [check_type], [obj_type], [db_name], [obj_name], [col_name], [message], [ref_link])
								SELECT 	@CheckNumber
										,N''Data Types''
										,N''USER_TABLE''
										,QUOTENAME(DB_NAME())
										,QUOTENAME(SCHEMA_NAME(t.schema_id)) + ''.'' + QUOTENAME(t.name)
										,QUOTENAME(c.name)
										,N''Columns storing date or time should use a temporal specific data type, but this column is using '' + ty.name + ''.''
										,N''http://expresssql.lowlydba.com/sp_sizeoptimiser.html#time-based-formats''
								FROM sys.columns as c
									inner join sys.tables as t on t.object_id = c.object_id
									inner join sys.types as ty on ty.user_type_id = c.user_type_id
								WHERE c.is_identity = 0 --exclude identity cols
									AND t.is_ms_shipped = 0 --exclude sys table
									AND (c.name LIKE ''%date%'' OR c.name LIKE ''%time%'')
									AND [c].[name] NOT LIKE ''%days%''
									AND ty.name NOT IN (''datetime'', ''datetime2'', ''datetimeoffset'', ''date'', ''smalldatetime'', ''time'');'
			FROM #Databases;
			EXEC sp_executesql @CheckSQL, N'@CheckNumber TINYINT', @CheckNumber = @CheckNumber;
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
			SELECT @CheckSQL = @CheckSQL + N'USE ' + QUOTENAME([database_name]) +  N'; WITH archaic AS (
								SELECT 	QUOTENAME(SCHEMA_NAME(t.schema_id)) + ''.'' + QUOTENAME(t.name) AS [obj_name]
										,QUOTENAME(c.name) AS [col_name]
										,N''Possible arbitrary variable length column in use. Is the '' + ty.name + N'' length of '' + CAST (c.max_length / 2 AS varchar(MAX)) + N'' based on requirements'' AS [message]
										,N''http://expresssql.lowlydba.com/sp_sizeoptimiser.html#arbitrary-varchar-length'' AS [ref_link]
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
										,N''Possible arbitrary variable length column in use. Is the '' + ty.name + N'' length of '' + CAST (c.max_length AS varchar(MAX)) + N'' based on requirements''
										,N''http://expresssql.lowlydba.com/sp_sizeoptimiser.html#arbitrary-varchar-length''
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
			EXEC sp_executesql @CheckSQL, N'@CheckNumber TINYINT', @CheckNumber = @CheckNumber;
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
			SELECT @CheckSQL = @CheckSQL + 'USE ' + QUOTENAME([database_name]) + ';
								WITH UnspecifiedVarChar AS (
									SELECT	QUOTENAME(SCHEMA_NAME(t.schema_id)) + ''.'' + QUOTENAME(t.name) AS [obj_name]
											,QUOTENAME(c.name) AS [col_name]
											,N''VARCHAR column without specified length, it should not have a length of '' + CAST (c.max_length AS varchar(10)) + '''' AS [message]
											,N''http://expresssql.lowlydba.com/sp_sizeoptimiser.html#unspecified-varchar-length'' AS [ref_link]
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
			EXEC sp_executesql @CheckSQL, N'@CheckNumber TINYINT', @CheckNumber = @CheckNumber;
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
			SELECT @CheckSQL = @CheckSQL + N'USE ' + QUOTENAME([database_name]) + N';
							INSERT INTO #results ([check_num], [check_type], [obj_type], [db_name], [obj_name], [col_name], [message], [ref_link])
							SELECT @CheckNumber
									,N''Data Types''
									,N''USER_TABLE''
									,QUOTENAME(DB_NAME())
									,QUOTENAME(SCHEMA_NAME(t.schema_id)) + ''.'' + QUOTENAME(t.name)
									,QUOTENAME(c.name)
									,N''Column is NVARCHAR(MAX) which allows very large row sizes. Consider a character limit.''
									,N''http://expresssql.lowlydba.com/sp_sizeoptimiser.html#mad-varchar-max''
							FROM sys.columns as c
									INNER JOIN sys.tables as t on t.object_id = c.object_id
									INNER JOIN sys.types as ty on ty.user_type_id = c.user_type_id
							WHERE t.is_ms_shipped = 0 --exclude sys table
									AND ty.[name] = ''nvarchar''
									AND c.max_length = -1;'
			FROM #Databases;
			EXEC sp_executesql @CheckSQL, N'@CheckNumber TINYINT', @CheckNumber = @CheckNumber;
		END; --NVARCHAR MAX Check

		/* NVARCHAR data type in Express*/
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
					SELECT @CheckSQL = @CheckSQL + N'USE ' + QUOTENAME([database_name]) + N';
													INSERT INTO #results ([check_num], [check_type], [obj_type], [db_name], [obj_name], [col_name], [message], [ref_link])
													SELECT	@CheckNumber
															,N''Data Types''
															,N''USER_TABLE''
															,QUOTENAME(DB_NAME())
															,QUOTENAME(SCHEMA_NAME([o].schema_id)) + ''.'' + QUOTENAME(OBJECT_NAME([o].object_id))
															,QUOTENAME([ac].[name])
															,N''nvarchar columns take 2x the space per char of varchar. Only use if you need Unicode characters.''
															,N''http://expresssql.lowlydba.com/sp_sizeoptimiser.html#nvarchar-in-express''
													FROM   [sys].[all_columns] AS [ac]
															INNER JOIN [sys].[types] AS [t] ON [t].[user_type_id] = [ac].[user_type_id]
															INNER JOIN [sys].[objects] AS [o] ON [o].object_id = [ac].object_id
													WHERE  [t].[name] = ''NVARCHAR''
															AND [o].[is_ms_shipped] = 0'
					FROM #Databases;
					EXEC sp_executesql @CheckSQL, N'@CheckNumber TINYINT', @CheckNumber = @CheckNumber;
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
			SELECT @CheckSQL = @CheckSQL + N'USE ' + QUOTENAME([database_name]) + N';
								INSERT INTO #results ([check_num], [check_type], [obj_type], [db_name], [obj_name], [col_name], [message], [ref_link])
								SELECT 	@CheckNumber
										,N''Data Types''
										,[o].[type_desc]
										,QUOTENAME(DB_NAME())
										,QUOTENAME(SCHEMA_NAME(o.schema_id)) + ''.'' + QUOTENAME(o.name)
										,QUOTENAME(ac.name)
										,N''Best practice is to use DECIMAL/NUMERIC instead of '' + st.name + '' for non floating point math.''
										,N''http://expresssql.lowlydba.com/sp_sizeoptimiser.html#float-and-real-data-types''
								FROM sys.all_columns AS ac
										INNER JOIN sys.objects AS o ON o.object_id = ac.object_id
										INNER JOIN sys.systypes AS st ON st.xtype = ac.system_type_id
								WHERE st.name IN(''FLOAT'', ''REAL'')
										AND o.type_desc = ''USER_TABLE'';'
			FROM #Databases;
			EXEC sp_executesql @CheckSQL, N'@CheckNumber TINYINT', @CheckNumber = @CheckNumber;
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
			SELECT @CheckSQL = @CheckSQL + N'USE ' + QUOTENAME([database_name]) + N';
								INSERT INTO #results ([check_num], [check_type], [obj_type], [db_name], [obj_name], [col_name], [message], [ref_link])
								SELECT 	@CheckNumber
										,N''Data Types''
										,[o].[type_desc]
										,QUOTENAME(DB_NAME())
										,QUOTENAME(SCHEMA_NAME(o.schema_id)) + ''.'' + QUOTENAME(o.name)
										,QUOTENAME(ac.name)
										,N''Deprecated data type in use: '' + st.name + ''.''
										,N''http://expresssql.lowlydba.com/sp_sizeoptimiser.html#deprecated-data-types''
								FROM sys.all_columns AS ac
										INNER JOIN sys.objects AS o ON o.object_id = ac.object_id
										INNER JOIN sys.systypes AS st ON st.xtype = ac.system_type_id
								WHERE st.name IN(''NEXT'', ''TEXT'', ''IMAGE'')
										AND o.type_desc = ''USER_TABLE'';'
			FROM #Databases;
			EXEC sp_executesql @CheckSQL, N'@CheckNumber TINYINT', @CheckNumber = @CheckNumber;
		END; --Don't use deprecated data types check

		/* BIGINT for identity values in Express*/
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
					SELECT @CheckSQL = @CheckSQL + N'USE ' + QUOTENAME([database_name]) + N';
										INSERT INTO #results ([check_num], [check_type], [obj_type], [db_name], [obj_name], [col_name], [message], [ref_link])
										SELECT  @CheckNumber
												,N''Data Types''
												,N''USER_TABLE''
												,QUOTENAME(DB_NAME())
												,QUOTENAME(SCHEMA_NAME(t.schema_id)) + ''.'' + QUOTENAME(t.name)
												,QUOTENAME(c.name)
												,N''BIGINT used on IDENTITY column in SQL Express. If values will never exceed 2,147,483,647 use INT instead.''
												,N''http://expresssql.lowlydba.com/sp_sizeoptimiser.html#bigint-as-identity''
											FROM sys.columns as c
												INNER JOIN sys.tables as t on t.object_id = c.object_id
												INNER JOIN sys.types as ty on ty.user_type_id = c.user_type_id
											WHERE t.is_ms_shipped = 0 --exclude sys table
												AND ty.name = ''BIGINT''
												AND c.is_identity = 1;'
					FROM #Databases;
					EXEC sp_executesql @CheckSQL, N'@CheckNumber TINYINT', @CheckNumber = @CheckNumber;
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
			SELECT @CheckSQL = @CheckSQL + N'USE ' + QUOTENAME([database_name]) + N';
								INSERT INTO #results ([check_num], [check_type], [obj_type], [db_name], [obj_name], [col_name], [message], [ref_link])
								SELECT 	@CheckNumber
										,N''Data Types''
										,[o].[type_desc]
										,QUOTENAME(DB_NAME())
										,QUOTENAME(SCHEMA_NAME(o.schema_id)) + ''.'' + QUOTENAME(o.name)
										,QUOTENAME(ac.name)
										,N''Column is '' + UPPER(st.name) + ''('' + CAST(ac.precision AS VARCHAR) + '','' + CAST(ac.scale AS VARCHAR) + '')''
											+ '' . Consider using an INT variety for space reduction since the scale is 0.''
										,N''http://expresssql.lowlydba.com/sp_sizeoptimiser.html#numeric-or-decimal-0-scale)''
								FROM sys.objects AS o
										INNER JOIN sys.all_columns AS ac ON ac.object_id = o.object_id
										INNER JOIN sys.systypes AS st ON st.xtype = ac.system_type_id
								WHERE ac.scale = 0
										AND ac.precision < 19
										AND st.name IN(''DECIMAL'', ''NUMERIC'')
										AND o.is_ms_shipped = 0;'
			FROM #Databases;
			EXEC sp_executesql @CheckSQL, N'@CheckNumber TINYINT', @CheckNumber = @CheckNumber;
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
			SELECT @CheckSQL = @CheckSQL + N'USE ' + QUOTENAME([database_name]) + N';
								INSERT INTO #results ([check_num], [check_type], [obj_type], [db_name], [obj_name], [col_name], [message], [ref_link])
								SELECT 	@CheckNumber
										,N''Data Types''
										,[o].[type_desc]
										,QUOTENAME(DB_NAME())
										,QUOTENAME(SCHEMA_NAME(o.schema_id)) + ''.'' + QUOTENAME(o.name)
										,QUOTENAME(ac.name)
										,N''Column is potentially an enum that should be a foreign key to a normalized table for data integrity, space savings, and performance.''
										,N''http://expresssql.lowlydba.com/sp_sizeoptimiser.html#enum-column-not-implemented-as-foreign-key''
								FROM sys.objects AS o
										INNER JOIN sys.all_columns AS ac ON ac.object_id = o.object_id
										INNER JOIN sys.systypes AS st ON st.xtype = ac.system_type_id
								WHERE (ac.[name] LIKE ''%Type'' OR ac.[name] LIKE ''%Status'')
									AND o.is_ms_shipped = 0
									AND st.[name] IN (''nvarchar'', ''varchar'', ''char'');'
			FROM #Databases;
			EXEC sp_executesql @CheckSQL, N'@CheckNumber TINYINT', @CheckNumber = @CheckNumber;
		 END; -- Enum columns not implemented as foreign key

		/* User DB or model db  Growth set past 10GB - ONLY IF EXPRESS*/
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
					SELECT @CheckSQL = @CheckSQL + N'USE ' + QUOTENAME([database_name]) + N';
									INSERT INTO #results ([check_num], [check_type], [obj_type], [db_name], [obj_name], [col_name], [message], [ref_link])
									SELECT 	@CheckNumber
											,N''File Growth''
											,N''DATABASE''
											,QUOTENAME(DB_NAME())
											,QUOTENAME(DB_NAME(database_id))
											,NULL
											,N''Database file '' + name + '' has a maximum growth set to '' + CASE
																												WHEN max_size = -1
																													THEN ''Unlimited''
																												WHEN max_size > 0
																													THEN CAST((max_size / 1024) * 8 AS VARCHAR(MAX))
																											END + '', which is over the user database maximum file size of 10GB.''
											,N''http://expresssql.lowlydba.com/sp_sizeoptimiser.html#database-growth-past-10GB''
									 FROM sys.master_files mf
									 WHERE (max_size > 1280000 OR max_size = -1) -- greater than 10GB or unlimited
										 AND [mf].[database_id] > 5
										 AND [mf].[data_space_id] > 0 -- limit doesn''t apply to log files;'
					FROM #Databases;
					EXEC sp_executesql @CheckSQL, N'@CheckNumber TINYINT', @CheckNumber = @CheckNumber;
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
					        ,N'http://expresssql.lowlydba.com/sp_sizeoptimiser.html#database-growth-type'
			        FROM [sys].[master_files] AS [mf]
				        INNER JOIN [sys].[databases] AS [sd] ON [sd].[database_id] = [mf].[database_id]
				        INNER JOIN #Databases AS [d] ON [d].[database_name] = [sd].[name]
			        WHERE [mf].[is_percent_growth] = 1
					        AND [mf].[data_space_id] = 1; --ignore log files
  				END;
		 END; -- User DB or model db growth set to % Check

		/* Default fill factor (EXPRESS ONLY)*/
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
					SELECT @CheckSQL = @CheckSQL + N'USE ' + QUOTENAME([database_name]) + N';
										INSERT INTO #results ([check_num], [check_type], [obj_type], [db_name], [obj_name], [col_name], [message], [ref_link])
										SELECT 	@CheckNumber
												,N''Architecture''
												,N''INDEX''
												,QUOTENAME(DB_NAME())
												,QUOTENAME(SCHEMA_NAME([o].[schema_id])) + ''.'' + QUOTENAME([o].[name]) + ''.'' + QUOTENAME([i].[name])
												,NULL
												,N''Non-default fill factor on this index. Not inherently bad, but will increase table size more quickly.''
												,N''http://expresssql.lowlydba.com/sp_sizeoptimiser.html#default-fill-factor''
										FROM [sys].[indexes] AS [i]
												INNER JOIN [sys].[objects] AS [o] ON [o].[object_id] = [i].[object_id]
										WHERE [i].[fill_factor] NOT IN(0, 100);'
					FROM #Databases;
					EXEC sp_executesql @CheckSQL, N'@CheckNumber TINYINT', @CheckNumber = @CheckNumber;
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
			SELECT @CheckSQL = @CheckSQL + N'USE ' + QUOTENAME([database_name]) +  N';
									INSERT INTO #results ([check_num], [check_type], [obj_type], [db_name], [obj_name], [col_name], [message], [ref_link])
									SELECT 	@CheckNumber
											,N''Architecture''
											,N''INDEX''
											,QUOTENAME(DB_NAME())
											,QUOTENAME(SCHEMA_NAME(t.schema_id)) + ''.'' + QUOTENAME(t.name)
											,NULL
											,''There are '' + CAST(COUNT(DISTINCT(i.index_id)) AS VARCHAR) + '' indexes on this table taking up '' + CAST(CAST(SUM(s.[used_page_count]) * 8 / 1024.00 AS DECIMAL(10, 2)) AS VARCHAR) + '' MB of space.''
											,''http://expresssql.lowlydba.com/sp_sizeoptimiser.html#number-of-indexes''
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
			EXEC sp_executesql @CheckSQL, N'@IndexNumThreshold TINYINT, @CheckNumber TINYINT', @IndexNumThreshold = @IndexNumThreshold, @CheckNumber = @CheckNumber;
		 END; -- Questionable number of indexes check

		/* Inefficient Indexes */
		SET @CheckNumber = @CheckNumber + 1;
		IF (@Verbose = 1)
			BEGIN;
				SET @Msg = CONCAT(N'Check ', @CheckNumber, ' - Inefficient indexes');
				RAISERROR(@Msg, 10, 1) WITH NOWAIT;
			END;
		BEGIN;

			SET @CheckSQL =
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
						END;

						/* Retrieve all indexes */
						SELECT  ac.[name] AS [col_name]
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
						DECLARE @MaxNumIndex BIGINT = (SELECT MAX(index_num) FROM #Indexes);

						/* Iterate through each index, adding together columns for each */
						WHILE @Counter <= @MaxNumIndex
						BEGIN
							DECLARE @IndexedColumns NVARCHAR(MAX) = N'''';
							DECLARE @IndexedColumnsInclude NVARCHAR(MAX) = N'''';

							/* Add together index columns */
							SELECT @IndexedColumns += CAST([col_name] AS SYSNAME)
							FROM #Indexes
							WHERE is_included_column = 0
								AND index_num = @Counter
							ORDER BY row_num;

							/* Add together index + included columns */
							SELECT @IndexedColumnsInclude += CAST([col_name] AS SYSNAME)
							FROM #Indexes
							WHERE index_num = @Counter
							ORDER BY row_num;

							/* Generate a checksum for index columns
								and index + included columns for each index */
							UPDATE #Indexes
							SET [ix_checksum] = CHECKSUM(@IndexedColumns), [ix_incl_checksum] = CHECKSUM(@IndexedColumnsInclude)
							WHERE index_num = @Counter;

							SET @Counter += 1;
						END;

						/* Narrow down to one row per index */
						SELECT DISTINCT [object_id], index_id, [ix_checksum], [ix_incl_checksum], [schema_id]
						INTO #IdxChecksum
						FROM #Indexes;

						/* Find duplicate indexes */
						SELECT COUNT(*) AS [num_dup_indexes], [ix_incl_checksum], [object_id]
						INTO #MatchingIdxInclChecksum
						FROM #IdxChecksum
						GROUP BY [ix_incl_checksum], [object_id]
						HAVING COUNT(*) > 1;

						/* Find overlapping indexes with same indexed columns */
						SELECT COUNT(*) AS [num_dup_indexes], [ix_checksum], [object_id]
						INTO #MatchingIdxChecksum
						FROM #IdxChecksum
						GROUP BY [ix_checksum], [object_id]
						HAVING COUNT(*) > 1

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
							INNER JOIN sys.indexes AS [i] ON [i].[index_id] = ic.index_id AND i.[object_id] = ic.[object_id]
						/* Dont include any indexes that are already identified as 100% duplicates */
						WHERE NOT EXISTS (SELECT * FROM #DuplicateIndex AS [di] WHERE [di].[object_id] = ic.[object_id] AND di.index_id = ic.index_id);
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
				   ,N'http://expresssql.lowlydba.com/sp_sizeoptimiser.html#inefficient-indexes'
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
				   ,N'http://expresssql.lowlydba.com/sp_sizeoptimiser.html#inefficient-indexes'
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
								LEFT JOIN [sys].[indexes] AS [i] ON i.object_id = t.object_id
														AND i.name = s.name
								LEFT JOIN [sys].[index_columns] AS [ic] ON [ic].[object_id] = [i].[object_id]
														AND [ic].[column_id] = [ac].[column_id]
														AND ic.index_id = i.index_id '
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
								AND [ac].[is_nullable] = 1 ';

			IF @HasTempStat = 1
				BEGIN;
					SET @CheckSQL = @CheckSQL + N'AND [s].[is_temporary] = 0 ';
				END;

			SET @CheckSQL = @CheckSQL + N'AND ([ic].[index_column_id] = 1 OR [ic].[index_column_id] IS NULL)
								AND ([i].[type_desc] =''NONCLUSTERED'' OR [i].[type_desc] IS NULL);

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

								+ /* Stat Header temp table*/ +
								N'INSERT INTO #StatsHeaderStaging
								EXEC sp_executesql @DBCCStatSQL
									,N''@SchemaTableName SYSNAME, @statName SYSNAME''
									,@SchemaTableName = @SchemaTableName
									,@statName = @statName; '

								+ /* Histogram temp table*/ +
								N'INSERT INTO #StatHistogramStaging
								EXEC sp_executesql @DBCCHistSQL
									,N''@SchemaTableName SYSNAME, @statName SYSNAME''
									,@SchemaTableName = @SchemaTableName
									,@statName = @statName;

								INSERT INTO #Stats
								SELECT	QUOTENAME(DB_NAME())
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
					,QUOTENAME([db_name]) AS "db_name"
					,QUOTENAME([schema_name]) + '.' + QUOTENAME([table_name])
					,QUOTENAME([col_name])
					,N'Candidate for converting to a space-saving sparse column based on NULL distribution of more than ' + CAST([threshold_null_perc] AS VARCHAR(3))+ ' percent.'
					,N'http://expresssql.lowlydba.com/sp_sizeoptimiser.html#sparse-columns'
			FROM #Stats
			WHERE [null_perc] >= [threshold_null_perc];
		END; -- Sparse column check

		/* Heap Tables*/
		SET @CheckNumber = @CheckNumber + 1;
		IF (@Verbose = 1)
			BEGIN;
				SET @Msg = CONCAT(N'Check ', @CheckNumber, ' - Heap Tables');
				RAISERROR(@Msg, 10, 1) WITH NOWAIT;
			END;
		BEGIN
			SET @CheckSQL = N'';
			SELECT @CheckSQL = @CheckSQL + N'USE ' + QUOTENAME([database_name]) + N';
								INSERT INTO #results ([check_num], [check_type], [obj_type], [db_name], [obj_name], [col_name], [message], [ref_link])
								SELECT 	@CheckNumber
										,N''Architecture''
										,N''INDEX''
										,QUOTENAME(DB_NAME())
										,QUOTENAME(SCHEMA_NAME([t].[schema_id])) + ''.'' + QUOTENAME([t].[name])
										,NULL
										,N''Heap tables can result in massive fragmentation and have additional indexing overhead.''
										,N''http://expresssql.lowlydba.com/sp_sizeoptimiser.html#heap-tables''
								FROM [sys].[tables] AS [t]
										INNER JOIN [sys].[indexes] AS [i] ON [i].[object_id] = [t].[object_id]
								WHERE [i].[type] = 0'
			FROM #Databases;
			EXEC sp_executesql @CheckSQL, N'@CheckNumber TINYINT', @CheckNumber = @CheckNumber;
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
		ORDER BY check_num, [check_type], [message], [db_name], obj_type, obj_name, [col_name];

	END TRY

	BEGIN CATCH;
		BEGIN;
			DECLARE @ErrorNumber INT = ERROR_NUMBER();
			DECLARE @ErrorLine INT = ERROR_LINE();
			DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
			DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
			DECLARE @ErrorState INT = ERROR_STATE();

			IF (@Debug = 1)
				BEGIN
					SET @msg = CONCAT('Actual error number: ', @ErrorNumber);
					RAISERROR(@msg, 16, 1);
					SET @msg = CONCAT('Actual line number: ', @ErrorLine);
					RAISERROR(@msg, 16, 1);
					SET @msg = CONCAT('Check number: ', @CheckNumber);
					RAISERROR(@msg, 16, 1);
				END;

			RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState) WITH NOWAIT;
		END;
	END CATCH;
END;
GO


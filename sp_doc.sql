SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_doc]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[sp_doc] AS' 
END
GO

ALTER PROCEDURE [dbo].[sp_doc]
					   @DatabaseName SYSNAME = NULL
					  ,@ExtendedPropertyName VARCHAR(100) = 'Description'
AS
SET NOCOUNT ON;

DECLARE @sql NVARCHAR(MAX);
DECLARE @ParmDefinition NVARCHAR(500);
DECLARE @QuotedDatabaseName SYSNAME;

/* TO DO */
/* Generate markdown for check constraint */
/* Generate markdown for default constraint */
/* Generate markdown for inline table value functions */
/* Generate markdown for triggers */
/* Generate markdown for unique constraint */

--Check if database name was passed.
IF (@DatabaseName IS NULL OR DB_ID(@DatabaseName) IS NULL)
    BEGIN;
	   THROW 51000, 'Database not available.', 1;
    END
ELSE
    SET @QuotedDatabaseName = QUOTENAME(@DatabaseName); --Avoid injections

--Create table to hold EP data
SET @sql = N'USE ' + @QuotedDatabaseName + '
CREATE TABLE #markdown ( 
   [id] INT IDENTITY(1,1),
   [value] NVARCHAR(MAX));
'

/***********************
Generate markdown for database
************************/
SET @sql = @sql + N'
--Database Name
INSERT INTO #markdown (value)
VALUES (CONCAT(''# '', @DatabaseName) COLLATE DATABASE_DEFAULT);' +

--Database extended properties
+ N'INSERT INTO #markdown (value)
SELECT CAST([value] AS VARCHAR(200))
FROM sys.extended_properties
WHERE class = 0
	AND name = @ExtendedPropertyName;' +

--Spacer
+ N'INSERT INTO #markdown (value)
VALUES ('''');' +

--Variables
+ N'DECLARE @objectid int;
';

/***********************
Generate markdown for tables
************************/
SET @sql = @sql + N'
INSERT INTO #markdown (value)
VALUES (''## Tables'')
	,('''')
	,(''<details><summary>Click to expand</summary>'')
	,('''');' +

--Build table of contents 
+ N'INSERT INTO #markdown (value)
SELECT CONCAT(''* ['', OBJECT_SCHEMA_NAME(object_id), ''.'', OBJECT_NAME(object_id), ''](#'', LOWER(OBJECT_SCHEMA_NAME(object_id)), LOWER(OBJECT_NAME(object_id)), '')'')
FROM sys.all_objects
WHERE type = ''U''
	AND is_ms_shipped = 0
ORDER BY OBJECT_SCHEMA_NAME(object_id), [name] ASC;' +

--Object details
+ N'DECLARE MY_CURSOR CURSOR 
  LOCAL STATIC READ_ONLY FORWARD_ONLY
FOR 
SELECT object_id 
FROM sys.tables
WHERE [type] = ''U''
ORDER BY OBJECT_SCHEMA_NAME(object_id), [name] ASC;

OPEN MY_CURSOR
FETCH NEXT FROM MY_CURSOR INTO @objectid
WHILE @@FETCH_STATUS = 0
BEGIN 

	INSERT INTO #markdown
	SELECT CONCAT(''### '', OBJECT_SCHEMA_NAME(@objectid), ''.'', OBJECT_NAME(@objectid));' +

	--Extended Properties
	+ N'INSERT INTO #markdown
	SELECT CAST([ep].[value] AS VARCHAR(200))
	FROM [sys].[all_objects] AS [o] 
		INNER JOIN [sys].[extended_properties] AS [ep] ON [o].[object_id] = [ep].[major_id]
	WHERE [o].[object_id] = @objectid
		AND [ep].[minor_id] = 0 --On the table

	INSERT INTO #markdown (value)
	VALUES ('''')
			,(CONCAT(''| Column | Type | Null | Foreign Key | '', @ExtendedPropertyName COLLATE DATABASE_DEFAULT, '' |''))
			,(''| --- | ---| --- | --- | --- | '');' +

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
			,CAST([ep].[value] AS VARCHAR(200))
			,'' | '')
	FROM [sys].[all_objects] AS [o] 
		INNER JOIN [sys].[columns] AS [c] ON [o].[object_id] = [c].[object_id]
		LEFT JOIN [sys].[extended_properties] AS [ep] ON [o].[object_id] = [ep].[major_id]
			AND [ep].[minor_id] > 0
			AND [ep].[minor_id] = [c].[column_id]
			AND [ep].[class] = 1 --Object/col
			AND [ep].[name] = @ExtendedPropertyName
		LEFT JOIN [sys].[foreign_key_columns] AS [fk] ON [fk].[parent_object_id] = [c].[object_id]
			AND [fk].[parent_column_id] = [c].[column_id]
	WHERE [o].[object_id] = @objectid;' +

	--Back to top
	+ N'INSERT INTO #markdown
	VALUES ('''')
		,(CONCAT(''[Back to top](#'', @DatabaseName COLLATE DATABASE_DEFAULT, '')''))

	FETCH NEXT FROM MY_CURSOR INTO @objectid;

END;
CLOSE MY_CURSOR;
DEALLOCATE MY_CURSOR;' +

--End collapsible table section
+ N'INSERT INTO #markdown
VALUES ('''')
	,(''</details>'')
	,('''');
'
--End markdown for tables

/***********************
Generate markdown for views
************************/
SET @sql = @sql + N'
INSERT INTO #markdown (value)
VALUES (''## Views'')
	,(''<details><summary>Click to expand</summary>'')
	,('''');' +

--Build table of contents
+ N'INSERT INTO #markdown (value)
SELECT CONCAT(''* ['', OBJECT_SCHEMA_NAME(object_id), ''.'', OBJECT_NAME(object_id), ''](#'', LOWER(OBJECT_SCHEMA_NAME(object_id)), LOWER(OBJECT_NAME(object_id)), '')'')
FROM sys.views
WHERE is_ms_shipped = 0
ORDER BY OBJECT_SCHEMA_NAME(object_id), [name] ASC;' +

--Object details
+ N'DECLARE MY_CURSOR CURSOR 
  LOCAL STATIC READ_ONLY FORWARD_ONLY
FOR 
SELECT object_id 
FROM sys.views
WHERE is_ms_shipped = 0
ORDER BY OBJECT_SCHEMA_NAME(object_id), [name] ASC;

OPEN MY_CURSOR
FETCH NEXT FROM MY_CURSOR INTO @objectid
WHILE @@FETCH_STATUS = 0
BEGIN 

	INSERT INTO #markdown
	SELECT CONCAT(''### '', OBJECT_SCHEMA_NAME(@objectid), ''.'', OBJECT_NAME(@objectid));' +

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
			,(''| --- | ---| --- | --- | '');' +

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
			,'' | '')
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
	VALUES(''##### Definition'')
		,(''<details><summary>Click to expand</summary>'')
		,('''');' +

	--Object definition
	+ N'INSERT INTO #markdown (value)
	VALUES (''```tsql'')
			,(OBJECT_DEFINITION(@objectid))
			,(''```'')
			,('''');' +

	--Back to top
	+ N'INSERT INTO #markdown
	VALUES (''</details>'')
		,('''')
		,(CONCAT(''[Back to top](#'', @DatabaseName COLLATE DATABASE_DEFAULT, '')''))
		,('''');

	FETCH NEXT FROM MY_CURSOR INTO @objectid;

END;
CLOSE MY_CURSOR;
DEALLOCATE MY_CURSOR;' +

--End collapsible view section
+ N'INSERT INTO #markdown
VALUES (''</details>'')
	,('''');
'
--End markdown for views

/***********************
Generate markdown for procedures
************************/
SET @sql = @sql + N'
INSERT INTO #markdown
VALUES (''## Stored Procedures'')
	,(''<details><summary>Click to expand</summary>'')
	,('''');' +

--Build table of contents
+ N'INSERT INTO #markdown
SELECT CONCAT(''* ['', OBJECT_SCHEMA_NAME(object_id), ''.'', OBJECT_NAME(object_id), ''](#'', LOWER(OBJECT_SCHEMA_NAME(object_id)), LOWER(OBJECT_NAME(object_id)), '')'')
FROM sys.procedures
WHERE is_ms_shipped = 0
ORDER BY OBJECT_SCHEMA_NAME(object_id), [name] ASC;' +

--Object details
+ N'DECLARE MY_CURSOR CURSOR 
  LOCAL STATIC READ_ONLY FORWARD_ONLY
FOR 
SELECT object_id 
FROM sys.procedures
WHERE is_ms_shipped = 0
ORDER BY OBJECT_SCHEMA_NAME(object_id), [name] ASC;

OPEN MY_CURSOR
FETCH NEXT FROM MY_CURSOR INTO @objectid
WHILE @@FETCH_STATUS = 0
BEGIN 

	INSERT INTO #markdown
	SELECT CONCAT(''### '', OBJECT_SCHEMA_NAME(@objectid), ''.'', OBJECT_NAME(@objectid));' +

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
				,(''| --- | --- | --- | '');

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
					END)
		  FROM [sys].[procedures] AS [proc]
			INNER JOIN [sys].[parameters] AS [param] ON [param].[object_id] = [proc].[object_id]
		  WHERE [proc].[object_id] = @objectid
		  ORDER BY [param].[parameter_id] ASC;
	END

	INSERT INTO #markdown (value)
	VALUES(''##### Definition'')
		,(''<details><summary>Click to expand</summary>'')
		,('''');' +

	--Object definition
	+ N'INSERT INTO #markdown (value)
	VALUES (''```tsql'')
			,(OBJECT_DEFINITION(@objectid))
			,('''')
			,(''```'')
			,('''');' +

	--Back to top
	+ N'INSERT INTO #markdown
	VALUES (''</details>'')
		,('''')
		,(CONCAT(''[Back to top](#'', @DatabaseName COLLATE DATABASE_DEFAULT, '')''))
		,('''');

	FETCH NEXT FROM MY_CURSOR INTO @objectid

END
CLOSE MY_CURSOR
DEALLOCATE MY_CURSOR;' +

--End collapsible view section
+ N'INSERT INTO #markdown
VALUES (''</details>'')
	,('''');
'
--End markdown for stored procedures

/***********************
Generate markdown for scalar functions
************************/
SET @sql = @sql + N'
INSERT INTO #markdown
VALUES (''## Scalar Functions'')
	,(''<details><summary>Click to expand</summary>'')
	,('''');' +

--Build table of contents
+ N'INSERT INTO #markdown
SELECT CONCAT(''* ['', OBJECT_SCHEMA_NAME([object_id]), ''.'', OBJECT_NAME([object_id]), ''](#'', LOWER(OBJECT_SCHEMA_NAME([object_id])), LOWER(OBJECT_NAME([object_id])), '')'')
FROM [sys].[objects]
WHERE [is_ms_shipped] = 0
	AND [type] = ''FN'' --SQL_SCALAR_FUNCTION
ORDER BY OBJECT_SCHEMA_NAME(object_id), [name] ASC;' +

--Object details
+ N'DECLARE MY_CURSOR CURSOR 
  LOCAL STATIC READ_ONLY FORWARD_ONLY
FOR 
SELECT [object_id]
FROM [sys].[objects]
WHERE [is_ms_shipped] = 0
	AND [type] = ''FN'' --SQL_SCALAR_FUNCTION
ORDER BY OBJECT_SCHEMA_NAME([object_id]), [name] ASC;

OPEN MY_CURSOR
FETCH NEXT FROM MY_CURSOR INTO @objectid
WHILE @@FETCH_STATUS = 0
BEGIN

	INSERT INTO #markdown
	SELECT CONCAT(''### '', OBJECT_SCHEMA_NAME(@objectid), ''.'', OBJECT_NAME(@objectid));' +

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
				,(''| --- | --- | --- | '');

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
					END)
		  FROM [sys].[objects] AS [o]
			INNER JOIN [sys].[parameters] AS [param] ON [param].[object_id] = [o].[object_id]
		  WHERE [o].[object_id] = @objectid
		  ORDER BY [param].[parameter_id] ASC;
	END;' +

	--Object definition
	+ N'INSERT INTO #markdown (value)
	VALUES(''##### Definition'')
		,(''<details><summary>Click to expand</summary>'')
		,('''');

	INSERT INTO #markdown (value)
	VALUES (''```tsql'')
			,(OBJECT_DEFINITION(@objectid))
			,('''')
			,(''```'')
			,(''''); ' +

	--Back to top
	+ N'INSERT INTO #markdown
	VALUES (''</details>'')
		,('''')
		,(CONCAT(''[Back to top](#'', @DatabaseName COLLATE DATABASE_DEFAULT, '')''))
		,('''');

	FETCH NEXT FROM MY_CURSOR INTO @objectid;

END;
CLOSE MY_CURSOR;
DEALLOCATE MY_CURSOR;' +

--End collapsible view section
+ N'INSERT INTO #markdown
VALUES (''</details>'')
	,('''');
'
--End markdown for scalar functions

/***********************
Generate markdown for table functions
************************/
SET @sql = @sql + N'
INSERT INTO #markdown
VALUES (''## Table Functions'')
	,(''<details><summary>Click to expand</summary>'')
	,('''');' +

--Build table of contents
+ N'INSERT INTO #markdown
SELECT CONCAT(''* ['', OBJECT_SCHEMA_NAME([object_id]), ''.'', OBJECT_NAME([object_id]), ''](#'', LOWER(OBJECT_SCHEMA_NAME([object_id])), LOWER(OBJECT_NAME([object_id])), '')'')
FROM [sys].[objects]
WHERE [is_ms_shipped] = 0
	AND [type] = ''IF'' --SQL_INLINE_TABLE_VALUED_FUNCTION
ORDER BY OBJECT_SCHEMA_NAME(object_id), [name] ASC;' +

--Object details
+ N'DECLARE MY_CURSOR CURSOR 
  LOCAL STATIC READ_ONLY FORWARD_ONLY
FOR 
SELECT [object_id]
FROM [sys].[objects]
WHERE [is_ms_shipped] = 0
	AND [type] = ''IF'' --SQL_INLINE_TABLE_VALUED_FUNCTION
ORDER BY OBJECT_SCHEMA_NAME([object_id]), [name] ASC;

OPEN MY_CURSOR
FETCH NEXT FROM MY_CURSOR INTO @objectid
WHILE @@FETCH_STATUS = 0
BEGIN

	INSERT INTO #markdown
	SELECT CONCAT(''### '', OBJECT_SCHEMA_NAME(@objectid), ''.'', OBJECT_NAME(@objectid));' +

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
				,(''| --- | --- | --- | '');

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
					END)
		  FROM [sys].[objects] AS [o]
			INNER JOIN [sys].[parameters] AS [param] ON [param].[object_id] = [o].[object_id]
		  WHERE [o].[object_id] = @objectid
		  ORDER BY [param].[parameter_id] ASC;
	END;' +

	--Object definition
	+ N'INSERT INTO #markdown (value)
	VALUES(''##### Definition'')
		,(''<details><summary>Click to expand</summary>'')
		,('''');

	INSERT INTO #markdown (value)
	VALUES (''```tsql'')
			,(OBJECT_DEFINITION(@objectid))
			,('''')
			,(''```'')
			,(''''); ' +

	--Back to top
	+ N'INSERT INTO #markdown
	VALUES (''</details>'')
		,('''')
		,(CONCAT(''[Back to top](#'', @DatabaseName COLLATE DATABASE_DEFAULT, '')''))
		,('''');

	FETCH NEXT FROM MY_CURSOR INTO @objectid;

END;
CLOSE MY_CURSOR;
DEALLOCATE MY_CURSOR;' +

--End collapsible view section
+ N'INSERT INTO #markdown
VALUES (''</details>'')
	,('''');
'

--End markdown for table functions

/***********************
Generate markdown for synonyms
************************/
SET @sql = @sql + N'
INSERT INTO #markdown
VALUES (''## Synonyms'')
	,(''<details><summary>Click to expand</summary>'')
	,(''''); ' +

--Build table of contents
+ N'INSERT INTO #markdown
SELECT CONCAT(''* ['', OBJECT_SCHEMA_NAME(object_id), ''.'', OBJECT_NAME(object_id), ''](#'', LOWER(OBJECT_SCHEMA_NAME(object_id)), LOWER(OBJECT_NAME(object_id)), '')'')
FROM sys.synonyms
WHERE is_ms_shipped = 0
ORDER BY OBJECT_SCHEMA_NAME(object_id), [name] ASC;' +

--Object details
+ N'DECLARE MY_CURSOR CURSOR 
  LOCAL STATIC READ_ONLY FORWARD_ONLY
FOR
SELECT [object_id]
FROM [sys].[synonyms]
WHERE [is_ms_shipped] = 0
ORDER BY OBJECT_SCHEMA_NAME([object_id]), [name] ASC;

OPEN MY_CURSOR
FETCH NEXT FROM MY_CURSOR INTO @objectid
WHILE @@FETCH_STATUS = 0
BEGIN 

	INSERT INTO #markdown
	SELECT CONCAT(''### '', OBJECT_SCHEMA_NAME(@objectid), ''.'', OBJECT_NAME(@objectid)); ' +

	--Extended properties
	+ N'INSERT INTO #markdown
	SELECT CAST([ep].[value] AS VARCHAR(200))
	FROM [sys].[all_objects] AS [o] 
		INNER JOIN [sys].[extended_properties] AS [ep] ON [o].[object_id] = [ep].[major_id]
	WHERE [o].[object_id] = @objectid
		AND [ep].[minor_id] = 0;

	INSERT INTO #markdown (value)
	VALUES ('''')
			,(''| Synonym | Base Object'')
			,(''| --- | --- | '');' +

	--Object mapping
	+ N'INSERT INTO #markdown
	SELECT CONCAT(OBJECT_SCHEMA_NAME([syn].[object_id]), ''.'', OBJECT_NAME([syn].[object_id])
			,'' | ''
			,CASE WHEN PARSENAME([base_object_name], 3) = DB_NAME()
				THEN CONCAT(''['', PARSENAME([base_object_name], 3), ''.'', PARSENAME([base_object_name], 2), ''.'', PARSENAME([base_object_name], 1), '']'', ''(#'', PARSENAME([base_object_name], 2), ''.'', PARSENAME([base_object_name], 1), '')'')
				ELSE CONCAT(PARSENAME([base_object_name], 3), PARSENAME([base_object_name], 2), PARSENAME([base_object_name], 1))
			END)
		FROM [sys].[synonyms] AS [syn]
		WHERE [syn].[object_id] = @objectid;' +

	--Back to top
	+ N'INSERT INTO #markdown
	VALUES (''</details>'')
		,('''')
		,(CONCAT(''[Back to top](#'', @DatabaseName COLLATE DATABASE_DEFAULT, '')''))
		,('''');

	FETCH NEXT FROM MY_CURSOR INTO @objectid

END
CLOSE MY_CURSOR
DEALLOCATE MY_CURSOR;' +

--End collapsible view section
+ N'INSERT INTO #markdown
VALUES (''</details>'')
	,('''');
'

--End markdown for synonyms

--Return all data
SET @sql = @sql + N'
SELECT [value]
FROM #markdown
ORDER BY [ID] ASC;'

SET @ParmDefinition = N'@ExtendedPropertyName SYSNAME, @DatabaseName SYSNAME';
EXEC sp_executesql @sql
	,@ParmDefinition
	,@ExtendedPropertyName
	,@DatabaseName;
GO
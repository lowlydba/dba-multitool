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

--Check if database name was passed.
IF (@DatabaseName IS NULL OR DB_ID(@DatabaseName) IS NULL)
    BEGIN;
	   THROW 51000, 'Database not available.', 1;
    END
ELSE
    SET @QuotedDatabaseName = QUOTENAME(@DatabaseName); --Avoid injections

SET @sql = N'USE ' + @QuotedDatabaseName + '

--Create table to hold EP data
CREATE TABLE #markdown ( 
   [id] INT IDENTITY(1,1),
   [value] NVARCHAR(MAX));
'

/* Generate markdown for check constraint */
/*SET @sql = @sql + N'
IF EXISTS (SELECT * FROM [sys].[all_objects] AS [o]
		  INNER JOIN [sys].[extended_properties] AS [ep] ON [ep].[major_id] = [o].[object_id]
		  WHERE [o].[is_ms_shipped] = 0 AND [o].[type] = ''C'')
BEGIN
    
    INSERT INTO #markdown
    VALUES  (''## Check Constraints'')
		 ,(''| Schema | Name | Comment |'')
		 ,(''| ------ | ---- | ------- |'');
    
    INSERT INTO #markdown
    SELECT CONCAT(SCHEMA_NAME([o].[schema_id]), '' | '', OBJECT_NAME([ep].major_id), '' | '', CAST([ep].[value] AS VARCHAR(200)))
    FROM [sys].[extended_properties] AS [ep]
	   INNER JOIN [sys].[all_objects] AS [o] ON [o].[object_id] = [ep].[major_id]
    WHERE   [ep].[name] = ''Description''
	   AND [o].[is_ms_shipped] = 0 -- User objects only
	   AND [o].[type] = ''C'' -- Check Constraints
    ORDER BY SCHEMA_NAME([o].[schema_id]), [o].[type_desc], OBJECT_NAME([ep].major_id);

END
'

/* Generate markdown for default constraint */
SET @sql = @sql + N'
IF EXISTS (SELECT * FROM [sys].[all_objects] AS [o]
		  INNER JOIN [sys].[extended_properties] AS [ep] ON [ep].[major_id] = [o].[object_id]
		  WHERE [o].[is_ms_shipped] = 0 AND [o].[type] = ''D'')
BEGIN
    
    INSERT INTO #markdown
    VALUES  (''## Default Constraints'')
		 ,(''| Schema | Name | Comment |'')
		 ,(''| ------ | ---- | ------- |'');
    
    INSERT INTO #markdown
    SELECT CONCAT(SCHEMA_NAME([o].[schema_id]), '' | '', OBJECT_NAME([ep].major_id), '' | '', CAST([ep].[value] AS VARCHAR(200)))
    FROM [sys].[extended_properties] AS [ep]
	   INNER JOIN [sys].[all_objects] AS [o] ON [o].[object_id] = [ep].[major_id]
    WHERE   [ep].[name] = ''Description''
	   AND [o].[is_ms_shipped] = 0 -- User objects only
	   AND [o].[type] = ''D'' -- Default Constraints
    ORDER BY SCHEMA_NAME([o].[schema_id]), [o].[type_desc], OBJECT_NAME([ep].major_id);
END
'

/* Generate markdown for inline table value functions */
SET @sql = @sql +  N'
IF EXISTS (SELECT * FROM [sys].[all_objects] AS [o]
		  INNER JOIN [sys].[extended_properties] AS [ep] ON [ep].[major_id] = [o].[object_id]
		  WHERE [o].[is_ms_shipped] = 0 AND [o].[type] = ''IF'')
BEGIN
    
    INSERT INTO #markdown
    VALUES  (''## Inline Table Value Functions'')
		 ,(''| Schema | Name | Comment |'')
		 ,(''| ------ | ---- | ------- |'');
    
    INSERT INTO #markdown
    SELECT CONCAT(SCHEMA_NAME([o].[schema_id]), '' | '', OBJECT_NAME([ep].major_id), '' | '', CAST([ep].[value] AS VARCHAR(200)))
    FROM [sys].[extended_properties] AS [ep]
	   INNER JOIN [sys].[all_objects] AS [o] ON [o].[object_id] = [ep].[major_id]
    WHERE   [ep].[name] = ''Description''
	   AND [o].[is_ms_shipped] = 0 -- User objects only
	   AND [o].[type] = ''IF'' -- Inline table value functions
    ORDER BY SCHEMA_NAME([o].[schema_id]), [o].[type_desc], OBJECT_NAME([ep].major_id);

END
'

/* Generate markdown for scalar functions */
SET @sql = @sql +  N'
IF EXISTS (SELECT * FROM [sys].[all_objects] AS [o]
		  INNER JOIN [sys].[extended_properties] AS [ep] ON [ep].[major_id] = [o].[object_id]
		  WHERE [o].[is_ms_shipped] = 0 AND [o].[type] = ''FN'')
BEGIN
    
    INSERT INTO #markdown
    VALUES  (''## Scalar Functions'')
		 ,(''| Schema | Name | Comment |'')
		 ,(''| ------ | ---- | ------- |'');
    
    INSERT INTO #markdown
    SELECT CONCAT(SCHEMA_NAME([o].[schema_id]), '' | '', OBJECT_NAME([ep].major_id), '' | '', CAST([ep].[value] AS VARCHAR(200)))
    FROM [sys].[extended_properties] AS [ep]
	   INNER JOIN [sys].[all_objects] AS [o] ON [o].[object_id] = [ep].[major_id]
    WHERE   [ep].[name] = ''Description''
	   AND [o].[is_ms_shipped] = 0 -- User objects only
	   AND [o].[type] = ''FN'' -- SCALAR_FUNCTIONS
    ORDER BY SCHEMA_NAME([o].[schema_id]), [o].[type_desc], OBJECT_NAME([ep].major_id);
END
'

/* Generate markdown for triggers */
SET @sql = @sql +  N'
IF EXISTS (SELECT * FROM [sys].[all_objects] AS [o]
		  INNER JOIN [sys].[extended_properties] AS [ep] ON [ep].[major_id] = [o].[object_id]
		  WHERE [o].[is_ms_shipped] = 0 AND [o].[type] = ''TR'')
BEGIN
    
    INSERT INTO #markdown
    VALUES  (''## Triggers'')
		 ,(''| Schema | Name | Comment |'')
		 ,(''| ------ | ---- | ------- |'');
    
    INSERT INTO #markdown
    SELECT CONCAT(SCHEMA_NAME([o].[schema_id]), '' | '', OBJECT_NAME([ep].major_id), '' | '', CAST([ep].[value] AS VARCHAR(200)))
    FROM [sys].[extended_properties] AS [ep]
	   INNER JOIN [sys].[all_objects] AS [o] ON [o].[object_id] = [ep].[major_id]
    WHERE   [ep].[name] = ''Description''
	   AND [o].[is_ms_shipped] = 0 -- User objects only
	   AND [o].[type] = ''TR'' -- TRIGGERS
    ORDER BY SCHEMA_NAME([o].[schema_id]), [o].[type_desc], OBJECT_NAME([ep].major_id);

END
'

/* Generate markdown for unique constraint */
SET @sql = @sql +  N'
IF EXISTS (SELECT * FROM [sys].[all_objects] AS [o]
		  INNER JOIN [sys].[extended_properties] AS [ep] ON [ep].[major_id] = [o].[object_id]
		  WHERE [o].[is_ms_shipped] = 0 AND [o].[type] = ''UQ'')
BEGIN
    
    INSERT INTO #markdown
    VALUES  (''## Check Constraints'')
		 ,(''| Schema | Name | Comment |'')
		 ,(''| ------ | ---- | ------- |'');
    
    INSERT INTO #markdown
    SELECT CONCAT(SCHEMA_NAME([o].[schema_id]), '' | '', OBJECT_NAME([ep].major_id), '' | '', CAST([ep].[value] AS VARCHAR(200)))
    FROM [sys].[extended_properties] AS [ep]
	   INNER JOIN [sys].[all_objects] AS [o] ON [o].[object_id] = [ep].[major_id]
    WHERE   [ep].[name] = ''Description''
	   AND [o].[is_ms_shipped] = 0 -- User objects only
	   AND [o].[type] = ''UQ'' -- Unique Constraints
    ORDER BY SCHEMA_NAME([o].[schema_id]), [o].[type_desc], OBJECT_NAME([ep].major_id);
END
'

/* Generate markdown for views */
SET @sql = @sql + N'


END
'*/


/***********************
Generate markdown for database
************************/
SET @sql = @sql + N'
--Database Name
INSERT INTO #markdown (value)
VALUES (CONCAT(''# '', @DatabaseName) COLLATE DATABASE_DEFAULT);

--Database ep
INSERT INTO #markdown (value)
SELECT CAST([value] AS VARCHAR(200))
FROM sys.extended_properties
WHERE class = 0
	AND name = @ExtendedPropertyName;

--Spacer
INSERT INTO #markdown (value)
VALUES ('''');
';

/***********************
Generate markdown for tables
************************/
SET @sql = @sql + N'
INSERT INTO #markdown (value)
VALUES (''## Tables'')
	,('''')
	,(''<details><summary>Click to expand</summary>'')
	,('''')' +

--Build table of contents for tables 
+ N'INSERT INTO #markdown (value)
SELECT CONCAT(''* ['', OBJECT_SCHEMA_NAME(object_id), ''.'', OBJECT_NAME(object_id), ''](#'', LOWER(OBJECT_SCHEMA_NAME(object_id)), LOWER(OBJECT_NAME(object_id)), '')'')
FROM sys.all_objects
WHERE type = ''U''
	AND is_ms_shipped = 0
ORDER BY OBJECT_SCHEMA_NAME(object_id), [name] ASC;

DECLARE @objectid int;

DECLARE MY_CURSOR CURSOR 
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
	SELECT CONCAT(''### '', OBJECT_SCHEMA_NAME(@objectid), ''.'', OBJECT_NAME(@objectid));

	--Table EP
	INSERT INTO #markdown
	SELECT CAST([ep].[value] AS VARCHAR(200))
	FROM [sys].[all_objects] AS [o] 
		INNER JOIN [sys].[extended_properties] AS [ep] ON [o].[object_id] = [ep].[major_id]
	WHERE [o].[object_id] = @objectid
		AND [ep].[minor_id] = 0 --On the table

	INSERT INTO #markdown (value)
	VALUES ('''')
			,(CONCAT(''| Column | Type | Null | Foreign Key | '', @ExtendedPropertyName COLLATE DATABASE_DEFAULT, '' |''))
			,(''| --- | ---| --- | --- | --- | '');

	INSERT INTO #markdown
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
	WHERE [o].[object_id] = @objectid;

	--Back to top
	INSERT INTO #markdown
	VALUES ('''')
		,(CONCAT(''[Back to top](#'', @DatabaseName COLLATE DATABASE_DEFAULT, '')''))

	FETCH NEXT FROM MY_CURSOR INTO @objectid

	END
CLOSE MY_CURSOR
DEALLOCATE MY_CURSOR

--End collapsible table section
INSERT INTO #markdown
VALUES ('''')
	,(''</details>'')
	,('''');
'

/***********************
Generate markdown for views
************************/
SET @sql = @sql +  N'
INSERT INTO #markdown (value)
VALUES (''## Views'')
	,(''<details><summary>Click to expand</summary>'')
	,('''')

--Build table of contents for views
INSERT INTO #markdown (value)
SELECT CONCAT(''* ['', OBJECT_SCHEMA_NAME(object_id), ''.'', OBJECT_NAME(object_id), ''](#'', LOWER(OBJECT_SCHEMA_NAME(object_id)), LOWER(OBJECT_NAME(object_id)), '')'')
FROM sys.views
WHERE is_ms_shipped = 0
ORDER BY OBJECT_SCHEMA_NAME(object_id), [name] ASC;

DECLARE MY_CURSOR CURSOR 
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
	SELECT CONCAT(''### '', OBJECT_SCHEMA_NAME(@objectid), ''.'', OBJECT_NAME(@objectid));

	--View EP
	INSERT INTO #markdown
	SELECT CAST([ep].[value] AS VARCHAR(200))
	FROM [sys].[all_objects] AS [o] 
		INNER JOIN [sys].[extended_properties] AS [ep] ON [o].[object_id] = [ep].[major_id]
	WHERE [o].[object_id] = @objectid
		AND [ep].[minor_id] = 0

	INSERT INTO #markdown (value)
	VALUES ('''')
			,(CONCAT(''| Column | Type | Null | '', @ExtendedPropertyName COLLATE DATABASE_DEFAULT, '' |''))
			,(''| --- | ---| --- | --- | '');

	--Insert data rows
	INSERT INTO #markdown
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
		,('''')

	INSERT INTO #markdown (value)
	VALUES (''```tsql'')
			,(OBJECT_DEFINITION(@objectid))
			,(''```'')
			,('''');

	--Back to top
	INSERT INTO #markdown
	VALUES (''</details>'')
		,('''')
		,(CONCAT(''[Back to top](#'', @DatabaseName COLLATE DATABASE_DEFAULT, '')''))
		,('''');

	FETCH NEXT FROM MY_CURSOR INTO @objectid

END
CLOSE MY_CURSOR
DEALLOCATE MY_CURSOR

--End collapsible view section
INSERT INTO #markdown
VALUES (''</details>'')
	,('''');
'
--End markdown for views


/***********************
Generate markdown for procedures
************************/
SET @sql = @sql +  N'
INSERT INTO #markdown
VALUES (''## Stored Procedures'')
	,(''<details><summary>Click to expand</summary>'')
	,('''');

--Build table of contents for views
INSERT INTO #markdown
SELECT CONCAT(''* ['', OBJECT_SCHEMA_NAME(object_id), ''.'', OBJECT_NAME(object_id), ''](#'', LOWER(OBJECT_SCHEMA_NAME(object_id)), LOWER(OBJECT_NAME(object_id)), '')'')
FROM sys.procedures
WHERE is_ms_shipped = 0
ORDER BY OBJECT_SCHEMA_NAME(object_id), [name] ASC;

DECLARE MY_CURSOR CURSOR 
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
	SELECT CONCAT(''### '', OBJECT_SCHEMA_NAME(@objectid), ''.'', OBJECT_NAME(@objectid));

	--Stored Procedure EP
	INSERT INTO #markdown
	SELECT CAST([ep].[value] AS VARCHAR(200))
	FROM [sys].[all_objects] AS [o] 
		INNER JOIN [sys].[extended_properties] AS [ep] ON [o].[object_id] = [ep].[major_id]
	WHERE [o].[object_id] = @objectid
		AND [ep].[minor_id] = 0;

	--Check for parameters
	IF EXISTS (SELECT * FROM [sys].[parameters] AS [param] WHERE [param].[object_id] = @objectid)
	BEGIN
		INSERT INTO #markdown (value)
		VALUES ('''')
				,(''| Parameter | Type | Output'')
				,(''| --- | --- | --- | '');

		--Insert data rows
		INSERT INTO #markdown
		select CONCAT([param].[name]
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
		,('''')

	INSERT INTO #markdown (value)
	VALUES (''```tsql'')
			,(OBJECT_DEFINITION(@objectid))
			,('''')
			,(''```'')
			,('''');

	--Back to top
	INSERT INTO #markdown
	VALUES (''</details>'')
		,('''')
		,(CONCAT(''[Back to top](#'', @DatabaseName COLLATE DATABASE_DEFAULT, '')''))
		,('''');

	FETCH NEXT FROM MY_CURSOR INTO @objectid

END
CLOSE MY_CURSOR
DEALLOCATE MY_CURSOR

--End collapsible stored procedure section
INSERT INTO #markdown
SELECT ''</details>'';
'
--End stored Procedures


--Return all data
SET @sql = @sql + N'
SELECT [value]
FROM #markdown
ORDER BY [ID] ASC
'

SET @ParmDefinition = N'@ExtendedPropertyName SYSNAME, @DatabaseName SYSNAME';
EXEC sp_executesql @sql
	,@ParmDefinition
	,@ExtendedPropertyName
	,@DatabaseName;

GO
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_doc]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[sp_doc] AS' 
END
GO

ALTER   PROCEDURE [dbo].[sp_doc]
					   @DatabaseName SYSNAME = NULL
						,@ExtendedPropertyName VARCHAR(100) = 'Description'
AS
SET NOCOUNT ON;

--Check if database name was passed.
IF (@DatabaseName IS NULL) 
    BEGIN;
	   THROW 51000, 'No database provided.', 1;
    END
ELSE
    SET @DatabaseName = QUOTENAME(@DatabaseName); --Avoid injections

DECLARE @sql NVARCHAR(MAX);
DECLARE @ParmDefinition NVARCHAR(500);
   

SET @sql = N'USE ' + @DatabaseName + '

--Create table to hold EP data
CREATE TABLE #markdown ( 
   [id] INT IDENTITY(1,1),
   [value] NVARCHAR(MAX));'

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

/* Generate markdown for stored procedures */
SET @sql = @sql +  N'
IF EXISTS (SELECT * FROM [sys].[all_objects] AS [o]
		  INNER JOIN [sys].[extended_properties] AS [ep] ON [ep].[major_id] = [o].[object_id]
		  WHERE [o].[is_ms_shipped] = 0 AND [o].[type] = ''P'')
BEGIN
    
    INSERT INTO #markdown
    VALUES  (''## Stored Procedures'')
		 ,(''| Schema | Name | Comment |'')
		 ,(''| ------ | ---- | ------- |'');
    
    INSERT INTO #markdown
    SELECT  CONCAT(SCHEMA_NAME([o].[schema_id]), '' | '', OBJECT_NAME([ep].major_id), '' | '', CAST([ep].[value] AS VARCHAR(200)))
    FROM [sys].[extended_properties] AS [ep]
	   INNER JOIN [sys].[all_objects] AS [o] ON [o].[object_id] = [ep].[major_id]
    WHERE   [ep].[name] = ''Description''
	   AND [o].[is_ms_shipped] = 0 -- User objects only
	   AND [o].[type] = ''P'' -- SQL_STORED_PROCEDURES
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
--Verify that one or more views exists w/ extended properties
IF EXISTS (SELECT * FROM [sys].[all_objects] AS [o]
		  INNER JOIN [sys].[extended_properties] AS [ep] ON [ep].[major_id] = [o].[object_id]
		  WHERE [o].[is_ms_shipped] = 0 AND [o].[type] = ''V'')
BEGIN

    --Build header rows 
    INSERT INTO #markdown
    VALUES(''## Views'')
	   , (''| Schema | Name | Col Name | Comment |'')
	   , (''| ------ | ---- | -------- | ------- |'');
    
    --Insert data rows
    INSERT INTO #markdown
    SELECT CONCAT(SCHEMA_NAME([o].[schema_id]), '' | '', OBJECT_NAME([ep].major_id), '' | '', ISNULL([syscols].[name], ''N/A'') , '' | '', CAST([ep].[value] AS VARCHAR(200)))
    FROM [sys].[extended_properties] AS [ep]
	   INNER JOIN [sys].[all_objects] AS [o] ON [o].[object_id] = [ep].[major_id]
	   LEFT JOIN [sys].[columns] AS [SysCols] ON [ep].[major_id] = [SysCols].[object_id]
							 AND [ep].[minor_id] = [SysCols].[column_id]
    WHERE   [ep].[name] = ''Description''
	   AND [o].[is_ms_shipped] = 0 -- User objects only
	   AND [o].[type] = ''V'' -- VIEW
    ORDER BY SCHEMA_NAME([o].[schema_id]), [o].[type_desc], OBJECT_NAME([ep].major_id);

END
'*/

/* Generate markdown for tables */
SET @sql = @sql +  N'

SELECT ''## Tables'';
SELECT ''<details><summary>User tables...</summary>

--Build table of contents for tables
SELECT CONCAT(''* ['', OBJECT_SCHEMA_NAME(object_id), ''.'', OBJECT_NAME(object_id), ''](#'', LOWER(OBJECT_SCHEMA_NAME(object_id)), LOWER(OBJECT_NAME(object_id)), '')'')
FROM sys.all_objects
WHERE type = ''U''
	AND is_ms_shipped = 0
ORDER BY OBJECT_SCHEMA_NAME(object_id), [name] ASC;

DECLARE @objectid int

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

		--Do something with Id here
	    INSERT INTO #markdown
		VALUES ('''')
			 ,(''| Column | DataType | '' + CAST(@ExtendedPropertyName AS VARCHAR(100)) COLLATE DATABASE_DEFAULT + '' |'')
			 ,(''| ------ | -------- | --------------- |'');
    
		INSERT INTO #markdown
		SELECT CONCAT('' | '', ISNULL([c].[name], ''N/A'') 
				, '' | '',
				CONCAT(UPPER(type_name(user_type_id)), 
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
				, '' | ''
				,CAST([ep].[value] AS VARCHAR(200)))
		FROM [sys].[all_objects] AS [o] 
			INNER JOIN [sys].[columns] AS [c] ON [o].[object_id] = [c].[object_id]
			LEFT JOIN [sys].[extended_properties] AS [ep] ON [o].[object_id] = [ep].[major_id]
				AND ep.[minor_id] > 0
				AND [ep].[minor_id] = [c].[column_id]
				AND ep.class = 1 --Object/col
				AND [ep].[name] = @ExtendedPropertyName
		WHERE [o].[object_id] = @objectid;

		INSERT INTO #markdown
		VALUES ('''');

		FETCH NEXT FROM MY_CURSOR INTO @objectid
    
END
CLOSE MY_CURSOR
DEALLOCATE MY_CURSOR

		 --Project all EPs
		SELECT [value]
		FROM #markdown
		ORDER BY [ID] ASC
		
		--End collapsible table section
		SELECT ''</details>'';
'
SET @ParmDefinition = N'@ExtendedPropertyName SYSNAME';
EXEC sp_executesql @sql
	,@ParmDefinition
	,@ExtendedPropertyName;

GO
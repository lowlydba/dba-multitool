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
					   @dbname SYSNAME = NULL
AS
SET NOCOUNT ON;

--Check if database name was passed.
IF (@dbname IS NULL) 
    BEGIN;
	   THROW 51000, 'No database provided.', 1;
    END
ELSE
    SET @dbname = QUOTENAME(@dbname); --Avoid injections

DECLARE @sql NVARCHAR(MAX);
   
/* Generate markdown for check constraint */
SET @sql = N'USE ' + @dbname + '

--Create table to hold EP data
CREATE TABLE #markdown ( 
   [id] INT IDENTITY(1,1),
   [value] NVARCHAR(MAX));
   
IF EXISTS (SELECT * FROM [sys].[all_objects] AS [o]
		  INNER JOIN [sys].[extended_properties] AS [ep] ON [ep].[major_id] = [o].[object_id]
		  WHERE [o].[is_ms_shipped] = 0 AND [o].[type] = ''C'')
BEGIN
    
    INSERT INTO #markdown
    VALUES  (''## Check Constraints'')
		 ,(''| Schema | Name | Comment |'')
		 ,(''| ------ | ---- | ------- |'');
    
    INSERT INTO #checkcon
    SELECT CONCAT(SCHEMA_NAME([o].[schema_id]), '' | '', OBJECT_NAME([ep].major_id), '' | '', CAST([ep].[value] AS VARCHAR(200)))
    FROM [sys].[extended_properties] AS [ep]
	   INNER JOIN [sys].[all_objects] AS [o] ON [o].[object_id] = [ep].[major_id]
    WHERE   [ep].[name] = ''MS_Description''
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
    WHERE   [ep].[name] = ''MS_Description''
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
    WHERE   [ep].[name] = ''MS_Description''
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
    WHERE   [ep].[name] = ''MS_Description''
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
    WHERE   [ep].[name] = ''MS_Description''
	   AND [o].[is_ms_shipped] = 0 -- User objects only
	   AND [o].[type] = ''P'' -- SQL_STORED_PROCEDURES
    ORDER BY SCHEMA_NAME([o].[schema_id]), [o].[type_desc], OBJECT_NAME([ep].major_id);
END
'

/* Generate markdown for tables */
SET @sql = @sql +  N'
IF EXISTS (SELECT * FROM [sys].[all_objects] AS [o]
		  INNER JOIN [sys].[extended_properties] AS [ep] ON [ep].[major_id] = [o].[object_id]
		  WHERE [o].[is_ms_shipped] = 0 AND [o].[type] = ''U'')
BEGIN
    
    INSERT INTO #markdown
    VALUES  (''## Tables'')
		 ,(''| Schema | Name | Col Name | Comment |'')
		 ,(''| ------ | ---- | -------- | ------- |'');
    
    INSERT INTO #markdown
    SELECT CONCAT(SCHEMA_NAME([o].[schema_id]), '' | '', OBJECT_NAME([ep].major_id), '' | '', ISNULL([syscols].[name], ''N/A'') , '' | '', CAST([ep].[value] AS VARCHAR(200)))
    FROM [sys].[extended_properties] AS [ep]
	   INNER JOIN [sys].[all_objects] AS [o] ON [o].[object_id] = [ep].[major_id]
	   LEFT JOIN [sys].[columns] AS [SysCols] ON [ep].[major_id] = [SysCols].[object_id]
							 AND [ep].[minor_id] = [SysCols].[column_id]
    WHERE   [ep].[name] = ''MS_Description''
	   AND [o].[is_ms_shipped] = 0 -- User objects only
	   AND [o].[type] = ''U'' -- USER_TABLE
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
    WHERE   [ep].[name] = ''MS_Description''
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
    WHERE   [ep].[name] = ''MS_Description''
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
    WHERE   [ep].[name] = ''MS_Description''
	   AND [o].[is_ms_shipped] = 0 -- User objects only
	   AND [o].[type] = ''V'' -- VIEW
    ORDER BY SCHEMA_NAME([o].[schema_id]), [o].[type_desc], OBJECT_NAME([ep].major_id);

END

    --Project all EPs
    SELECT [value]
    FROM #markdown
    ORDER BY [ID] ASC;
'
EXEC sp_executesql @sql;

GO
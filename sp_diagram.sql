SET NOCOUNT ON;
SET ANSI_NULLS ON;
GO

/***************************/
/* Create stored procedure */
/***************************/
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_diagram]') AND [type] IN (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[sp_diagram] AS';
END
GO

ALTER PROCEDURE [dbo].[sp_diagram]
	 @DatabaseName SYSNAME = NULL
    ,@Output VARCHAR(50) = 'markdown'
    ,@Verbose BIT = 1
    ,@Chart VARCHAR(25) = 'flowchart'
    ,@Direction VARCHAR(10) = NULL
    ,@Size SMALLINT = 1

WITH RECOMPILE
AS

/*
sp_diagram - Generate mermaid diagrams from databases.

Part of the DBA MultiTool https://dba-multitool.org

Version: 20220314

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

	EXEC dbo.sp_diagram @DatabaseName = 'WideWorldImporters';

*/

/*
TODO: Handle overall issue of this not working well with even small-medium sized databases
(i.e. WideWorldImporters) in flowchart (better) or erDiagram (worse) and the character
limit that can only be overcome via HTML version due JS config params.

If it can't work usefully in markdown, not sure this is worth pursuing...
*/

BEGIN
	SET NOCOUNT ON;

    DECLARE @Sql NVARCHAR(MAX)
        ,@QuotedDatabaseName SYSNAME
        ,@Msg NVARCHAR(MAX)
        -- Default to flowchart notation
        ,@Notation1 VARCHAR(20) = ' -- '
        ,@Notation2 VARCHAR(20) = ' --> ';

    -- Set diagram notation
    IF (@Chart = 'erDiagram')
        BEGIN
            SELECT @Notation1 = ' ||--o{ ';
            SELECT @Notation2 = ' : ';
            SELECT @Chart = 'erDiagram'; -- Case must match for js
        END;

    -- Check Size
    IF (@Size <> 100 AND @Output = 'markdown')
        BEGIN
            SELECT @Msg = '@Size is not applicable to markdown. It will be ignored.';
            RAISERROR(@Msg, 10, 1) WITH NOWAIT;
        END

    -- Check Chart
    IF (@Chart NOT IN ('flowchart', 'erDiagram'))
        BEGIN
            SELECT @Msg = '@Chart must be either ''graph'' or ''erDiagram''.';
            RAISERROR(@Msg, 16, 1) WITH NOWAIT;
        END
    ELSE IF (@Chart = 'erDiagram')
        BEGIN
            IF (@Direction IS NOT NULL)
                BEGIN
                    SELECT @Msg = '@Direction is not applicable to erDiagrams. It will be ignored.';
                    RAISERROR(@Msg, 10, 1) WITH NOWAIT;
                END
            SELECT @Direction = '';
        END
    ELSE IF (@Chart = 'flowchart' AND @Direction IS NULL)
        BEGIN
            SELECT @Msg = 'Using default Direction of ''LR''.';
            SELECT @Direction = 'LR';
            RAISERROR(@Msg, 10, 1) WITH NOWAIT;
        END

    -- Check Direction
    IF (@Chart = 'flowchart' AND @Direction NOT IN ('TD', 'LR', 'BT', 'RL'))
        BEGIN
            SELECT @Msg = '@Direction must be one of: ''TD'', ''LR'', ''BT'', ''RL''.';
            RAISERROR(@Msg, 16, 1) WITH NOWAIT;
        END

    -- Check database name
	IF (@DatabaseName IS NULL)
		BEGIN
			SELECT @DatabaseName = DB_NAME();
			IF (@Verbose = 1)
				BEGIN;
					SELECT @Msg = 'No database provided, assuming current database.';
					RAISERROR(@Msg, 10, 1) WITH NOWAIT;
				END;
		END
	ELSE IF (DB_ID(@DatabaseName) IS NULL)
		BEGIN;
			SELECT @Msg = 'Database not available.';
			RAISERROR(@Msg, 16, 1);
		END;

    SELECT @QuotedDatabaseName = QUOTENAME(@DatabaseName); --Avoid injections

    -- Build diagram
	SELECT @Sql = N'USE ' + @QuotedDatabaseName + ';
        CREATE TABLE #markdown (
	        [id] INT IDENTITY(1,1),
	        [value] NVARCHAR(MAX));

        DECLARE @SchemaId INT; ';

    IF (@Output = 'markdown')
        BEGIN;
            SELECT @Sql = @Sql + N'
                INSERT INTO #markdown
                SELECT ''```mermaid''
                ';
        END
    ELSE IF (@Output = 'html')
        BEGIN;
                SELECT @Sql = @Sql + N'
                INSERT INTO #markdown
                SELECT CONCAT(''<!DOCTYPE html>'', CHAR(13), CHAR(10)
                    ,''<html lang="en">'', CHAR(13), CHAR(10)
                    ,''<head>'', CHAR(13), CHAR(10)
                    ,''<meta charset="utf-8">'', CHAR(13), CHAR(10)
                    ,''<style>'', CHAR(13), CHAR(10)
                    ,''.mermaid {'', CHAR(13), CHAR(10)
                    ,''width: 100%; }'', CHAR(13), CHAR(10)
                    ,''</style>'', CHAR(13), CHAR(10)
                    ,''</head>'', CHAR(13), CHAR(10)
                    ,''<body>'', CHAR(13), CHAR(10)
                    ,''<div class="mermaid">'', CHAR(13), CHAR(10)); ';
        END

    SELECT @Sql = CONCAT(@Sql, '
    INSERT INTO #markdown
    SELECT ''', @chart, ' ', @Direction, ''';

    DECLARE [obj_cursor] CURSOR
	LOCAL STATIC READ_ONLY FORWARD_ONLY
	FOR
	SELECT [schema_id]
	FROM [sys].[schemas]
	WHERE [schema_id] < 16384
		AND [name] NOT IN (''sys'', ''guest'', ''INFORMATION_SCHEMA'')
        AND EXISTS (SELECT 1
                    FROM sys.foreign_keys fk
                        INNER JOIN sys.tables fk_tab ON fk_tab.object_id = fk.parent_object_id
                        INNER JOIN sys.tables pk_tab ON pk_tab.object_id = fk.referenced_object_id
                    WHERE fk_tab.schema_id = schemas.schema_id)
	ORDER BY [name] ASC;

	OPEN [obj_cursor]
	FETCH NEXT FROM [obj_cursor] INTO @SchemaId;

	WHILE @@FETCH_STATUS = 0
	BEGIN; ');

    IF (@Chart = 'flowchart')
        BEGIN
            SELECT @Sql = CONCAT(@Sql, '
                INSERT INTO #markdown
                SELECT ''subgraph '' + SCHEMA_NAME(@SchemaId); ');
        END

    IF (@Chart = 'flowchart')
    BEGIN
        SELECT @Sql = CONCAT(@Sql, '
            INSERT INTO #markdown
            SELECT CONCAT(fk_tab.name
                        ,''', @Notation1, '''
                        ,SUBSTRING(column_names, 1, LEN(column_names) -1)
                        ,''', @Notation2, '''
                        ,pk_tab.name) ');
    END
    ELSE IF (@Chart = 'erDiagram')
    BEGIN
    SELECT @Sql = CONCAT(@Sql, '
            INSERT INTO #markdown
            SELECT CONCAT(CONCAT(SCHEMA_NAME(fk_tab.schema_id), ''-'', fk_tab.name)
                        ,''', @Notation1, '''
                        ,CONCAT(SCHEMA_NAME(pk_tab.schema_id), ''-'', pk_tab.name)
                        ,''', @Notation2, '''
                        ,SUBSTRING(column_names, 1, LEN(column_names) -1)) ');
    END

    SELECT @Sql = CONCAT(@Sql, '
        FROM sys.foreign_keys fk
            INNER JOIN sys.tables fk_tab ON fk_tab.object_id = fk.parent_object_id
            INNER JOIN sys.tables pk_tab ON pk_tab.object_id = fk.referenced_object_id
            CROSS APPLY (SELECT CONCAT(col.[name], '', '')
                        FROM sys.foreign_key_columns fk_c
                            INNER JOIN sys.columns col ON fk_c.parent_object_id = col.object_id
                                AND fk_c.parent_column_id = col.column_id
                        WHERE fk_c.parent_object_id = fk_tab.object_id
                            AND fk_c.constraint_object_id = fk.object_id
                                    ORDER BY col.column_id
                                    FOR XML PATH ('''') ) D (column_names)
        WHERE fk_tab.schema_id = @SchemaId; ');


    IF (@Chart = 'flowchart')
        BEGIN
            SELECT @Sql = @Sql + N'
                INSERT INTO #markdown
                SELECT ''end''; ';
        END
    ELSE IF (@Chart = 'erDiagram')
        BEGIN
            SELECT @Sql = CONCAT(@Sql, '
            DECLARE @TableID INT;

            DECLARE [TableCursor] CURSOR
            LOCAL STATIC READ_ONLY FORWARD_ONLY
            FOR
            SELECT [t].[object_id]
            FROM [sys].[tables] [t]
            WHERE [t].[type] = ''U''
                AND [t].[is_ms_shipped] = 0
            ORDER BY OBJECT_SCHEMA_NAME([t].[object_id]), [t].[name] ASC;

            OPEN [TableCursor]
            FETCH NEXT FROM [TableCursor] INTO @TableID
            WHILE @@FETCH_STATUS = 0
            BEGIN

            INSERT INTO #markdown
            SELECT CONCAT(SCHEMA_NAME(schema_id), ''-'', name, '' {'', CHAR(13), CHAR(10))
            from sys.tables
            where object_id = @TableID
            UNION ALL
            SELECT CONCAT(TYPE_NAME([user_type_id]), '' '', name)
            from sys.columns c
            where c.object_id = @TableID
            UNION ALL
            SELECT '' }''

            FETCH NEXT FROM [TableCursor] INTO @TableID;

            END;
            CLOSE [TableCursor];
            DEALLOCATE [TableCursor];');
        END

    SELECT @Sql = @Sql + N'
        FETCH NEXT FROM [obj_cursor] INTO @SchemaId;
    END;
	CLOSE [obj_cursor];
	DEALLOCATE [obj_cursor]; ';

    IF (@Output = 'markdown')
        BEGIN;
            SELECT @Sql = @Sql + N'
                INSERT INTO #markdown
                SELECT ''```''; ';
        END
    ELSE IF (@Output = 'html')
        BEGIN;
                SELECT @Sql = @Sql + N'
                INSERT INTO #markdown
                SELECT CONCAT(''</div>'', CHAR(13), CHAR(10)
                    ,''<script src="https://cdn.jsdelivr.net/npm/mermaid/dist/mermaid.min.js"></script>'', CHAR(13), CHAR(10)
                    ,''<script>mermaid.initialize({startOnLoad:true});'', CHAR(13), CHAR(10)
                    ,''</script>'', CHAR(13), CHAR(10)
                    ,''</head>'', CHAR(13), CHAR(10)
                    ,''</body>'', CHAR(13), CHAR(10)
                    ,''</html>'', CHAR(13), CHAR(10)); ';
        END

    SELECT @Sql = @Sql + N'
    SELECT [value] FROM #markdown;';

    EXEC sp_executesql @Sql;
END;

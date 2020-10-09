
IF  EXISTS (SELECT * FROM sys.fn_listextendedproperty(N'Description' , N'SCHEMA',N'dbo', N'PROCEDURE',N'sp_estindex', NULL,NULL))
EXEC sys.sp_dropextendedproperty @name=N'Description' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'sp_estindex'
GO

IF  EXISTS (SELECT * FROM sys.fn_listextendedproperty(N'@TableName' , N'SCHEMA',N'dbo', N'PROCEDURE',N'sp_estindex', NULL,NULL))
EXEC sys.sp_dropextendedproperty @name=N'@TableName' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'sp_estindex'
GO

IF  EXISTS (SELECT * FROM sys.fn_listextendedproperty(N'@SqlMajorVersion' , N'SCHEMA',N'dbo', N'PROCEDURE',N'sp_estindex', NULL,NULL))
EXEC sys.sp_dropextendedproperty @name=N'@SqlMajorVersion' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'sp_estindex'
GO

IF  EXISTS (SELECT * FROM sys.fn_listextendedproperty(N'@SchemaName' , N'SCHEMA',N'dbo', N'PROCEDURE',N'sp_estindex', NULL,NULL))
EXEC sys.sp_dropextendedproperty @name=N'@SchemaName' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'sp_estindex'
GO

IF  EXISTS (SELECT * FROM sys.fn_listextendedproperty(N'@IsUnique' , N'SCHEMA',N'dbo', N'PROCEDURE',N'sp_estindex', NULL,NULL))
EXEC sys.sp_dropextendedproperty @name=N'@IsUnique' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'sp_estindex'
GO

IF  EXISTS (SELECT * FROM sys.fn_listextendedproperty(N'@IndexColumns' , N'SCHEMA',N'dbo', N'PROCEDURE',N'sp_estindex', NULL,NULL))
EXEC sys.sp_dropextendedproperty @name=N'@IndexColumns' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'sp_estindex'
GO

IF  EXISTS (SELECT * FROM sys.fn_listextendedproperty(N'@IncludeColumns' , N'SCHEMA',N'dbo', N'PROCEDURE',N'sp_estindex', NULL,NULL))
EXEC sys.sp_dropextendedproperty @name=N'@IncludeColumns' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'sp_estindex'
GO

IF  EXISTS (SELECT * FROM sys.fn_listextendedproperty(N'@Filter' , N'SCHEMA',N'dbo', N'PROCEDURE',N'sp_estindex', NULL,NULL))
EXEC sys.sp_dropextendedproperty @name=N'@Filter' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'sp_estindex'
GO

IF  EXISTS (SELECT * FROM sys.fn_listextendedproperty(N'@FillFactor' , N'SCHEMA',N'dbo', N'PROCEDURE',N'sp_estindex', NULL,NULL))
EXEC sys.sp_dropextendedproperty @name=N'@FillFactor' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'sp_estindex'
GO

IF  EXISTS (SELECT * FROM sys.fn_listextendedproperty(N'@DatabaseName' , N'SCHEMA',N'dbo', N'PROCEDURE',N'sp_estindex', NULL,NULL))
EXEC sys.sp_dropextendedproperty @name=N'@DatabaseName' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'sp_estindex'
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
    -- Unit testing only
    ,@SqlMajorVersion TINYINT = 0
AS
BEGIN

SET NOCOUNT ON;

/*
sp_estindex - Estimate a new index's size and statistics.

Part of the DBA MultiTool http://dba-multitool.org

Version: Version: 20201009

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

-- TODO: 
    -- Build unit tests
    -- Handle clustered indexes
    -- Revisit overall flow / order of operations

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
    ,@IsHeap BIT = 0
    ,@IsClusterUnique BIT = 0
    ,@ObjectID INT
    ,@IndexID INT
    ,@ParmDefinition NVARCHAR(MAX) = N''
    ,@NumRows BIGINT
    ,@UseDatabase NVARCHAR(200)
    ,@UniqueSql VARCHAR(10)
    ,@IncludeSql VARCHAR(2048);

BEGIN TRY 

    -- Find Version
	IF (@SqlMajorVersion = 0)
		BEGIN;
			SET @SqlMajorVersion = CAST(SERVERPROPERTY('ProductMajorVersion') AS TINYINT);
		END;

    /* Validate Fill Factor */
    IF (@FillFactor > 100 OR @FillFactor < 1)
        BEGIN;
            SET @Msg = 'Fill factor must be between 1 and 100.';
            RAISERROR(@Msg, 16, 1);
        END;

    /* Validate Database */
    IF (@DatabaseName IS NULL)
        BEGIN;
            SET @DatabaseName = DB_NAME();
            SET @Msg = 'No database provided, assuming current database.';
            RAISERROR(@Msg, 10, 1) WITH NOWAIT;
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
            SET @Msg = 'No schema provided, assuming dbo.';
            RAISERROR(@Msg, 10, 1) WITH NOWAIT;
        END;

	-- Validate Version
	IF (@SqlMajorVersion < 11)
		BEGIN;
			SET @Msg = 'SQL Server versions below 2012 are not supported, sorry!';
			RAISERROR(@Msg, 16, 1);
		END;

    -- Set variables with validated params
    SET @QualifiedTable = CONCAT(QUOTENAME(@SchemaName), '.', QUOTENAME(@TableName));
    SET @UseDatabase = N'USE ' + @DatabaseName + '; ';
    IF (@IsUnique = 1)
        SET @UniqueSql = ' UNIQUE ';
    IF (@IncludeColumns IS NOT NULL)
        SET @IncludeSql = CONCAT(' INCLUDE(', @IncludeColumns, ') ');

    -- Find object id
    SET @Sql = CONCAT(@UseDatabase,
        N'SELECT @ObjectID = [object_id]
        FROM [sys].[all_objects]
        WHERE [object_id] = OBJECT_ID(@TableName)');
	SET @ParmDefinition = N'@TableName SYSNAME
						,@ObjectID BIGINT OUTPUT';
    EXEC sp_executesql @Sql
    ,@ParmDefinition
    ,@TableName
    ,@ObjectID OUTPUT;

    -- Determine Heap or Clustered
    SET @Sql = CONCAT(@UseDatabase,
        N'SELECT @IsHeap = CASE [type] WHEN 0 THEN 1 ELSE 0 END
            ,@IsClusterUnique = [is_unique]
         FROM [sys].[indexes] 
         WHERE [object_id] = OBJECT_ID(@TableName) 
         AND [type] IN (1, 0)');
	SET @ParmDefinition = N'@TableName SYSNAME, @IsHeap BIT OUTPUT, @IsClusterUnique BIT OUTPUT';
	EXEC sp_executesql @Sql
		,@ParmDefinition
		,@TableName
		,@IsHeap OUTPUT
        ,@IsClusterUnique OUTPUT;

    -- Safety check for leftover index from previous run
    SET @DropIndexSql = CONCAT(@UseDatabase, 'DROP INDEX IF EXISTS', QUOTENAME(@IndexName), ' ON ', @QualifiedTable); 
    EXEC sp_executesql @DropIndexSql;

    -- Fetch missing index stats before creation
    DROP TABLE IF EXISTS ##TempMissingIndex;
    SET @Sql = CONCAT(@UseDatabase,
    N'SELECT id.[statement] 
        ,id.[equality_columns] 
        ,id.[inequality_columns] 
        ,id.[included_columns] 
        ,gs.[unique_compiles] 
        ,gs.[user_seeks]
        ,gs.[user_scans] 
        ,gs.[avg_total_user_cost] -- Average cost of the user queries that could be reduced
        ,gs.[avg_user_impact]  -- %
    INTO ##TempMissingIndex
    FROM [sys].[dm_db_missing_index_group_stats] gs
    INNER JOIN [sys].[dm_db_missing_index_groups] ig ON gs.[group_handle] = ig.[index_group_handle]
    INNER JOIN [sys].[dm_db_missing_index_details] id ON ig.[index_handle] = id.[index_handle]
    WHERE id.[database_id] = DB_ID()
        AND id.[object_id] = @ObjectID
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
    SET @Sql = CONCAT(@UseDatabase, 'DBCC SHOW_STATISTICS ("', @QualifiedTable,'", ', QUOTENAME(@IndexName), ')');
    EXEC sp_executesql @Sql;

    /***************************/
    /* Get missing index stats */
    /***************************/
    DECLARE @QuotedKeyColumns NVARCHAR(2048)
        ,@QuotedInclColumns NVARCHAR(2048);

    --Get index columns in same format as dmv table
    SET @Sql = CONCAT(@UseDatabase,
    N'SELECT    @QuotedKeyColumns = CASE [ic].[is_included_column] WHEN 0
									THEN COALESCE(@QuotedKeyColumns + '', '', '''') + QUOTENAME([ac].[name])
									ELSE @QuotedKeyColumns 
                                    END,
	            @QuotedInclColumns = CASE [ic].[is_included_column] WHEN 1
									THEN COALESCE(@QuotedInclColumns + '', '', '''') + QUOTENAME([ac].[name])
									ELSE @QuotedInclColumns 
                                    END
    FROM [sys].[indexes] AS [i]
        INNER JOIN [sys].[index_columns] AS [ic] ON [i].[index_id] = [ic].[index_id]
            AND [ic].object_id = [i].object_id
        INNER JOIN [sys].[all_columns] AS [ac] ON [ac].object_id = [ic].object_id
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
        ,*
    FROM ##TempMissingIndex
    WHERE COALESCE([equality_columns] + ', ', '') + [inequality_columns] = @QuotedKeyColumns
        AND ([included_columns] = @QuotedInclColumns OR [included_columns] IS NULL)

    /************************************************/
    /* Estimate index size - does NOT consider:     */
    /* Partitioning, allocation pages, LOB values,  */
    /* compression, or sparse columns               */
    /************************************************/ 
    IF (@IndexType = 'CLUSTERED') --https://docs.microsoft.com/en-us/sql/relational-databases/databases/estimate-the-size-of-a-clustered-index?view=sql-server-ver15
        BEGIN;
            SELECT 'Clustered indexes not supported yet.';
            RETURN;
        END;
    ELSE IF (@IndexType = 'NONCLUSTERED') -- http://dba-multitool.org/est-nonclustered-index-size
    BEGIN;
        DECLARE @NumVariableKeyCols INT = 0
            ,@MaxVarKeySize INT = 0
            ,@NumFixedKeyCols INT = 0
            ,@FixedKeySize INT = 0
            ,@NumKeyCols INT = 0
            ,@NullCols INT = 0
            ,@IndexNullBitmap INT = 0
            ,@VariableKeySize INT = 0
            ,@TotalFixedKeySize INT = 0
            ,@IndexRowSize INT = 0
            ,@IndexRowsPerPage INT = 0;

        /**************************/
        /* 1. Calculate variables */
        /**************************/
        -- Row count
        SET @Sql = CONCAT(@UseDatabase,
        N'SELECT @NumRows = SUM([ps].[row_count])
        FROM [sys].[objects] AS [o]
            INNER JOIN [sys].[dm_db_partition_stats] AS [ps] ON [o].[object_id] = [ps].[object_id]
        WHERE [o].[type] = ''U''
            AND [o].[is_ms_shipped] = 0
            AND [ps].[index_id] < 2
            AND [o].[object_id] = @ObjectID
        GROUP BY [o].[schema_id], [o].[name];')
        SET @ParmDefinition = N'@ObjectID BIGINT, @NumRows BIGINT OUTPUT';
	    EXEC sp_executesql @Sql
		,@ParmDefinition
		,@ObjectID
        ,@NumRows OUTPUT;

        --Key types and sizes
        SET @Sql = CONCAT(@UseDatabase,
        N'SELECT @NumVariableKeyCols = SUM(CASE
                    WHEN TYPE_NAME([ac].[user_type_id]) IN(''varchar'', ''nvarchar'', ''text'', ''ntext'', ''image'', ''varbinary'', ''xml'')
                    THEN 1
                    ELSE 0
                END),
            @MaxVarKeySize = SUM(CASE
                    WHEN TYPE_NAME([ac].[user_type_id]) IN(''varchar'', ''nvarchar'', ''text'', ''ntext'', ''image'', ''varbinary'', ''xml'')
                    THEN CASE [ac].[max_length]
                                WHEN -1
                                THEN(4000 + 2) -- use same estimation as the query engine for max lenths
                                ELSE COL_LENGTH(OBJECT_NAME([i].object_id), [ac].[name])
                            END
                    ELSE 0
                END), 
            @NumFixedKeyCols = SUM(CASE
                    WHEN TYPE_NAME([ac].[user_type_id]) NOT IN(''varchar'', ''nvarchar'', ''text'', ''ntext'', ''image'', ''varbinary'', ''xml'')
                    THEN 1
                    ELSE 0
                END), 
            @FixedKeySize = SUM(CASE
                    WHEN TYPE_NAME([ac].[user_type_id]) NOT IN(''varchar'', ''nvarchar'', ''text'', ''ntext'', ''image'', ''varbinary'', ''xml'')
                    THEN COL_LENGTH(OBJECT_NAME([i].object_id), [ac].[name])
                    ELSE 0
                END),
            @NullCols = SUM(CAST([ac].[is_nullable] AS TINYINT))
        FROM [sys].[indexes] AS [i]
            INNER JOIN [sys].[index_columns] AS [ic] ON [i].[index_id] = [ic].[index_id]
                AND [ic].object_id = [i].object_id
            INNER JOIN [sys].[all_columns] AS [ac] ON [ac].object_id = [ic].object_id
                AND [ac].[column_id] = [ic].[column_id]
        WHERE [i].[name] = @IndexName
            AND [i].[object_id] = @ObjectID
            AND [i].[is_hypothetical] = 1
            AND [ic].[is_included_column] = 0');
        SET @ParmDefinition = N'@IndexName SYSNAME, @ObjectID BIGINT, @NumVariableKeyCols INT OUTPUT,
            @MaxVarKeySize INT OUTPUT, @NumFixedKeyCols INT OUTPUT, @FixedKeySize INT OUTPUT,
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

        -- Account for data row locator for non-unique
        IF (@IsHeap = 1 AND @IsUnique = 0)
            BEGIN;
                SET @NumKeyCols = @NumKeyCols + 1;
                SET @NumVariableKeyCols = @NumVariableKeyCols + 1;
                SET @MaxVarKeySize = @MaxVarKeySize + 8; --heap RID
            END;
        ELSE IF (@IsHeap = 0 AND @IsUnique = 0)
            BEGIN;
                DECLARE @ClusterNumVarKeyCols INT
                    ,@MaxClusterVarKeySize INT
                    ,@ClusterNumFixedKeyCols INT
                    ,@MaxClusterFixedKeySize INT
                    ,@ClusterNullCols INT = 0;

                --Clustered keys and sizes not included in the new index
                Set @Sql = CONCAT(@UseDatabase,
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
                SELECT @ClusterNumVarKeyCols = SUM(CASE
                            WHEN TYPE_NAME([ac].[user_type_id]) IN(''varchar'', ''nvarchar'', ''text'', ''ntext'', ''image'', ''varbinary'', ''xml'')
                            THEN 1
                            ELSE 0
                        END),
                    @MaxClusterVarKeySize = SUM(CASE
                            WHEN TYPE_NAME([ac].[user_type_id]) IN(''varchar'', ''nvarchar'', ''text'', ''ntext'', ''image'', ''varbinary'', ''xml'')
                            THEN CASE [ac].[max_length]
                                        WHEN -1
                                        THEN(4000 + 2) -- use same estimation as the query engine for max lenths
                                        ELSE COL_LENGTH(OBJECT_NAME([i].object_id), [ac].[name])
                                    END
                            ELSE 0
                        END), 
                    @ClusterNumFixedKeyCols = SUM(CASE
                            WHEN TYPE_NAME([ac].[user_type_id]) NOT IN(''varchar'', ''nvarchar'', ''text'', ''ntext'', ''image'', ''varbinary'', ''xml'')
                            THEN 1
                            ELSE 0
                        END), 
                    @MaxClusterFixedKeySize = SUM(CASE
                            WHEN TYPE_NAME([ac].[user_type_id]) NOT IN(''varchar'', ''nvarchar'', ''text'', ''ntext'', ''image'', ''varbinary'', ''xml'')
                            THEN COL_LENGTH(OBJECT_NAME([i].object_id), [ac].[name])
                            ELSE 0
                        END),
                    @ClusterNullCols = SUM(CAST([ac].[is_nullable] AS TINYINT))
                FROM [sys].[indexes] AS [i]
                    INNER JOIN [sys].[index_columns] AS [ic] ON [i].[index_id] = [ic].[index_id]
                        AND [ic].object_id = [i].object_id
                    INNER JOIN [sys].[all_columns] AS [ac] ON [ac].object_id = [ic].object_id
                        AND [ac].[column_id] = [ic].[column_id]
                WHERE [i].[type] = 1 --Clustered
                    AND [i].[object_id] = @ObjectID
                    AND [ac].[name] NOT IN (SELECT [name] FROM [NewIndexCol]);')
                SET @ParmDefinition = N'@IndexName SYSNAME, @ObjectID BIGINT, @ClusterNumVarKeyCols INT OUTPUT,
                    @MaxClusterVarKeySize INT OUTPUT, @ClusterNumFixedKeyCols INT OUTPUT,
                    @MaxClusterFixedKeySize INT OUTPUT, @ClusterNullCols INT OUTPUT';
                EXEC sp_executesql @Sql
                ,@ParmDefinition
                ,@IndexName
                ,@ObjectID
                ,@ClusterNumVarKeyCols OUTPUT
                ,@MaxClusterVarKeySize OUTPUT
                ,@ClusterNumFixedKeyCols OUTPUT
                ,@MaxClusterFixedKeySize OUTPUT
                ,@ClusterNullCols OUTPUT;

                -- Add counts from clustered index cols 
                SET @NumKeyCols = @NumKeyCols + (@ClusterNumVarKeyCols + @ClusterNumFixedKeyCols)
                SET @FixedKeySize = @FixedKeySize + @MaxClusterFixedKeySize 
                SET @NumVariableKeyCols = @NumVariableKeyCols + @ClusterNumVarKeyCols
                SET @MaxVarKeySize = @MaxVarKeySize + @MaxClusterVarKeySize
                SET @NullCols = @NullCols + @ClusterNullCols;

                IF (@IsClusterUnique = 0)
                    BEGIN;
                        SET @MaxVarKeySize = @MaxVarKeySize + 4;
                        SET @NumVariableKeyCols = @NumVariableKeyCols + 1;
                        SET @NumKeyCols = @NumKeyCols + 1;
                    END;
            END;

        -- Account for index null bitmap
        IF (@NullCols > 0)
            BEGIN;
                SET @IndexNullBitmap = 2 + ((@NullCols + 7) / 8) 
            END;

        -- Calculate variable length data size
        -- Assumes each col is 100% full
        IF (@NumVariableKeyCols > 0)
            BEGIN;
                SET @VariableKeySize = 2 + (@NumVariableKeyCols * 2) + @MaxVarKeySize; --The bytes added to @MaxVarKeySize are for tracking each variable column.
            END;

        -- Calculate index row size
        SET @IndexRowSize = @FixedKeySize + @VariableKeySize + @IndexNullBitmap + 1 + 6 -- + 1 (for row header overhead of an index row) + 6 (for the child page ID pointer)

        --Calculate number of index rows / page
        SET @IndexRowsPerPage = FLOOR(8096 / (@IndexRowSize + 2)) -- + 2 for the row's entry in the page's slot array.

        /****************************************************************************/
        /* 2. Calculate the Space Used to Store Index Information in the Leaf Level */
        /****************************************************************************/
        -- Specify the number of fixed-length and variable-length columns at the leaf level
        -- and calculate the space that is required for their storage
        DECLARE @NumLeafCols INT = @NumKeyCols
            ,@FixedLeafSize INT = @FixedKeySize
            ,@NumVariableLeafCols INT = @NumVariableKeyCols
            ,@MaxVarLeafSize INT = @MaxVarKeySize
            ,@LeafNullBitmap INT = 0
            ,@VariableLeafSize INT = 0
            ,@LeafRowSize INT = 0
            ,@LeafRowsPerPage INT = 0
            ,@FreeRowsPerPage INT = 0
            ,@NumLeafPages INT = 0
            ,@LeafSpaceUsed INT = 0;

        IF (@IncludeColumns IS NOT NULL)
            BEGIN;
                DECLARE @NumVariableInclCols INT = 0
                    ,@MaxVarInclSize INT = 0
                    ,@NumFixedInclCols INT = 0
                    ,@FixedInclSize INT = 0;

                --Incl types and sizes
                SET @Sql = CONCAT(@UseDatabase,
                N'SELECT @NumVariableInclCols = SUM(CASE
                            WHEN TYPE_NAME([ac].[user_type_id]) IN(''varchar'', ''nvarchar'', ''text'', ''ntext'', ''image'', ''varbinary'', ''xml'')
                            THEN 1
                            ELSE 0
                        END),
                    @MaxVarInclSize = SUM(CASE
                            WHEN TYPE_NAME([ac].[user_type_id]) IN(''varchar'', ''nvarchar'', ''text'', ''ntext'', ''image'', ''varbinary'', ''xml'')
                            THEN CASE [ac].[max_length]
                                        WHEN -1
                                        THEN (4000 + 2) -- use same estimation as the query engine for max lenths
                                        ELSE COL_LENGTH(OBJECT_NAME([i].object_id), [ac].[name])
                                    END
                            ELSE 0
                        END), 
                    @NumFixedInclCols = SUM(CASE
                            WHEN TYPE_NAME([ac].[user_type_id]) NOT IN(''varchar'', ''nvarchar'', ''text'', ''ntext'', ''image'', ''varbinary'', ''xml'')
                            THEN 1
                            ELSE 0
                        END), 
                    @FixedInclSize = SUM(CASE
                            WHEN TYPE_NAME([ac].[user_type_id]) NOT IN(''varchar'', ''nvarchar'', ''text'', ''ntext'', ''image'', ''varbinary'', ''xml'')
                            THEN COL_LENGTH(OBJECT_NAME([i].object_id), [ac].[name])
                            ELSE 0
                        END)
                FROM [sys].[indexes] AS [i]
                    INNER JOIN [sys].[index_columns] AS [ic] ON [i].[index_id] = [ic].[index_id]
                        AND [ic].object_id = [i].object_id
                    INNER JOIN [sys].[all_columns] AS [ac] ON [ac].object_id = [ic].object_id
                        AND [ac].[column_id] = [ic].[column_id]
                WHERE [i].[name] = @IndexName
                    AND [i].[object_id] = @ObjectID
                    AND [i].[is_hypothetical] = 1
                    AND [ic].[is_included_column] = 1;');
                SET @ParmDefinition = N'@IndexName SYSNAME, @ObjectID BIGINT, @NumVariableInclCols INT OUTPUT,
                    @MaxVarInclSize INT OUTPUT, @NumFixedInclCols INT OUTPUT, @FixedInclSize INT OUTPUT';
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
                        SET @MaxVarLeafSize = @MaxVarLeafSize + @MaxClusterVarKeySize

                        IF (@IsClusterUnique = 0)
                            BEGIN;
                                SET @NumLeafCols = @NumLeafCols + 1;
                                SET @NumVariableLeafCols = @NumVariableLeafCols + 1;
                                SET @MaxVarLeafSize = @MaxVarLeafSize + 4;
                            END;
                    END;
            END; 
        
        -- Account for index null bitmap
        SET @LeafNullBitmap = 2 + ((@NumLeafCols + 7) / 8);

        -- Calculate variable length data size
        -- Assumes each col is 100% full
        IF (@NumVariableLeafCols > 0)
            BEGIN;
                SET @VariableLeafSize = 2 + (@NumVariableLeafCols * 2) + @MaxVarLeafSize;
            END;

        -- Calculate index row size
        SET @LeafRowSize = @FixedLeafSize + @VariableLeafSize + @LeafNullBitmap + 1; -- +1 for row header overhead of an index row)

        -- Calculate number of index rows / page
        SET @LeafRowsPerPage = FLOOR(8096 / (@LeafRowSize + 2)); -- + 2 for the row's entry in the page's slot array.

        -- Calculate free rows / page
        SET @FreeRowsPerPage = 8096 * (( 100 - @FillFactor) / 100) / (@LeafRowSize + 2); -- + 2 for the row's entry in the page's slot array.

        -- Calculate pages for all rows
        SET @NumLeafPages = CEILING(@NumRows / (@LeafRowsPerPage - @FreeRowsPerPage));

        -- Calculate size of index at leaf level
        SET @LeafSpaceUsed = 8192 * @NumLeafPages;

        /*********************************************************************************/
        /* 3. Calculate the Space Used to Store Index Information in the Non-leaf Levels */
        /*********************************************************************************/
        DECLARE @NonLeafLevels INT = 0,
            @NumIndexPages INT = 0,
            @IndexSpaceUsed INT = 0,
            @Test NUMERIC(30,15);

        -- Calculate the number of non-leaf levels in the index
        SET @NonLeafLevels = CEILING(1 + LOG(@IndexRowsPerPage) * (@NumLeafPages / @IndexRowsPerPage));
        
        --Formula: IndexPages = ∑Level (Num_Leaf_Pages/Index_Rows_Per_Page^Level)where 1 <= Level <= Levels
        WHILE (@NonLeafLevels > 1)
            BEGIN
                DECLARE @TempIndexPages FLOAT;

                -- TempIndexPages may be exceedingly small, so catch any arith overflows and call it 0
                BEGIN TRY
                    SET @TempIndexPages = @NumLeafPages / POWER(@IndexRowsPerPage, @NonLeafLevels);
                    SET @NumIndexPages = @NumIndexPages + @TempIndexPages;
                    SET @NonLeafLevels = @NonLeafLevels - 1;
                END TRY
                BEGIN CATCH
                    SET @NonLeafLevels = @NonLeafLevels - 1;
                END CATCH
            END;
        
        -- Calculate size of the index
        SET @IndexSpaceUsed = 8192 * @NumIndexPages;

        /**************************************/
        /* 4. Total index and leaf space used */
        /**************************************/
        DECLARE @Total INT = 0;

        SET @Total = @LeafSpaceUsed + @IndexSpaceUsed;

        SELECT @Total/1024 AS [Est. KB]
            ,CAST(ROUND(@Total/1024.0/1024.0,2,1) AS DECIMAL(30,2)) AS [Est. MB]
            ,CAST(ROUND(@Total/1024.0/1024.0/1024.0,2,1) AS DECIMAL(30,4)) AS [Est. GB];
    END;
END TRY
BEGIN CATCH;
    BEGIN;
        DECLARE @ErrorNumber INT = ERROR_NUMBER();
        DECLARE @ErrorLine INT = ERROR_LINE();
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();

        GOTO CleanupIndex

        SET @ErrorMessage = CONCAT(QUOTENAME(OBJECT_NAME(@@PROCID)), ': "', @ErrorMessage, '" at actual line ', @ErrorLine);
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState) WITH NOWAIT;
    END;
END CATCH;

GOTO CleanupIndex;

CleanupIndex:
EXEC sp_executesql @DropIndexSql;

END

EXEC sys.sp_addextendedproperty @name=N'@DatabaseName', @value=N'Target database of the index''s table.' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'sp_estindex'
GO

EXEC sys.sp_addextendedproperty @name=N'@FillFactor', @value=N'Optional fill factor for the index.' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'sp_estindex'
GO

EXEC sys.sp_addextendedproperty @name=N'@Filter', @value=N'Optional filter for the index. Default is 100.' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'sp_estindex'
GO

EXEC sys.sp_addextendedproperty @name=N'@IncludeColumns', @value=N'Optional comma separated list of include columns.' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'sp_estindex'
GO

EXEC sys.sp_addextendedproperty @name=N'@IndexColumns', @value=N'Comma separated list of key columns.' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'sp_estindex'
GO

EXEC sys.sp_addextendedproperty @name=N'@IsUnique', @value=N'Whether or not the index is UNIQUE. Default is 0.' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'sp_estindex'
GO

EXEC sys.sp_addextendedproperty @name=N'@SchemaName', @value=N'Target schema of the index''s table. Default is ''dbo''.' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'sp_estindex'
GO

EXEC sys.sp_addextendedproperty @name=N'@SqlMajorVersion', @value=N'For unit testing only.' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'sp_estindex'
GO

EXEC sys.sp_addextendedproperty @name=N'@TableName', @value=N'Target table for the index. Default is current database.' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'sp_estindex'
GO

EXEC sys.sp_addextendedproperty @name=N'Description', @value=N'Estimate a new index''s size and statistics.' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'sp_estindex'
GO
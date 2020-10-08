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
    ,@IncludedColumns NVARCHAR(2048) = NULL
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

Version: Version: 20201008

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

    EXEC dbo.sp_estindex @SchemaName = 'dbo', @tableName = 'Marathon', @IndexColumns = 'racer_id, finish_time, is_disqualified';

    EXEC dbo.sp_estindex @tableName = 'Marathon', @IndexColumns = 'racer_id, finish_time, is_disqualified', @Filter = 'WHERE racer_id IS NOT NULL', @FillFactor = 90;

*/

DECLARE @Sql NVARCHAR(MAX) = N''
    ,@QualifiedTable NVARCHAR(257)
    ,@IndexName SYSNAME = CONCAT('sp_estindex_hypothetical_index_', CAST(GETDATE() AS INT))
    ,@DropIndexSql NVARCHAR(MAX)
    ,@Msg NVARCHAR(MAX) = N''
    ,@IndexType SYSNAME = 'NONCLUSTERED'
    ,@IsUnique BIT = 0
    ,@IsHeap BIT = 0
    ,@ObjectID INT
    ,@IndexID INT
    ,@ParmDefinition NVARCHAR(MAX) = N''
    ,@NumRows BIGINT
    ,@UseDatabase NVARCHAR(200)
    ,@Unique VARCHAR(10);

BEGIN TRY 

    -- TODO: 
        -- Add EPs
        -- Build unit tests
        -- Allow other index types
        -- Size up included columns
        -- cleanup mode
        -- Provide missing index score

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
        BEGIN;
            SET @Unique = 'UNIQUE ';
        END;

    -- Find object id
    SET @Sql = N'USE ' + @DatabaseName + ';
        SELECT @ObjectID = [object_id]
        FROM [sys].[all_objects]
        WHERE [object_id] = OBJECT_ID(@TableName);';  
	SET @ParmDefinition = N'@TableName SYSNAME
						,@ObjectID BIGINT OUTPUT';
    EXEC sp_executesql @Sql
    ,@ParmDefinition
    ,@TableName
    ,@ObjectID OUTPUT;

    -- Determine Heap or Clustered
    SET @Sql = CONCAT(@UseDatabase,
        N'IF EXISTS (SELECT 1 FROM [sys].[indexes] WHERE [object_id] = OBJECT_ID(@TableName) AND [type] = 0)
	        SET @IsHeap = 1');
	SET @ParmDefinition = N'@TableName SYSNAME
						,@IsHeap BIT OUTPUT';
	EXEC sp_executesql @Sql
		,@ParmDefinition
		,@TableName
		,@IsHeap OUTPUT;

    -- Safety check for leftover index from previous run
    SET @DropIndexSql = CONCAT(@UseDatabase, 'DROP INDEX IF EXISTS', QUOTENAME(@IndexName), ' ON ', @QualifiedTable);
    EXEC sp_executesql @DropIndexSql;

    -- Create the hypothetical index
    SET @Sql = CONCAT(@UseDatabase, 'CREATE ', @Unique, @IndexType, ' INDEX ', QUOTENAME(@IndexName), ' ON ', @QualifiedTable, '(', @IndexColumns, ') ', @Filter, ' WITH (STATISTICS_ONLY = -1)');
    EXEC sp_executesql @Sql;
    
    -- Get statistics
    SET @Sql = CONCAT(@UseDatabase, 'DBCC SHOW_STATISTICS ("', @QualifiedTable,'", ', QUOTENAME(@IndexName), ')');
    EXEC sp_executesql @Sql;

    
    IF (@IndexType = 'CLUSTERED') --https://docs.microsoft.com/en-us/sql/relational-databases/databases/estimate-the-size-of-a-clustered-index?view=sql-server-ver15
        BEGIN;
            SELECT 'Clustered indexes not supported yet.'
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
        Set @Sql = CONCAT(@UseDatabase,
        N'SELECT @NumVariableKeyCols = SUM(CASE
                    WHEN TYPE_NAME([ac].[user_type_id]) IN(''varchar'', ''nvarchar'', ''text'', ''image'', ''varbinary'')
                    THEN 1
                    ELSE 0
                END),
            @MaxVarKeySize = SUM(CASE
                    WHEN TYPE_NAME([ac].[user_type_id]) IN(''varchar'', ''nvarchar'', ''text'', ''image'', ''varbinary'')
                    THEN CASE [ac].[max_length]
                                WHEN -1
                                THEN(4000 + 2) -- use same estimation as the query engine for max lenths
                                ELSE COL_LENGTH(OBJECT_NAME([i].object_id), [ac].[name])
                            END
                    ELSE 0
                END), 
            @NumFixedKeyCols = SUM(CASE
                    WHEN TYPE_NAME([ac].[user_type_id]) NOT IN(''varchar'', ''nvarchar'', ''text'', ''image'', ''varbinary'')
                    THEN 1
                    ELSE 0
                END), 
            @FixedKeySize = SUM(CASE
                    WHEN TYPE_NAME([ac].[user_type_id]) NOT IN(''varchar'', ''nvarchar'', ''text'', ''image'', ''varbinary'')
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
            AND [i].[is_hypothetical] = 1;');

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

        -- Account for data row locator
        SET @NumKeyCols = @NumVariableKeyCols + @NumFixedKeyCols;

        IF (@IsHeap = 1)
            BEGIN;
                SET @NumKeyCols = @NumKeyCols + 1;
                SET @NumVariableKeyCols = @NumVariableKeyCols + 1;
                SET @MaxVarKeySize = @MaxVarKeySize + 8; --heap RID
            END;
        ELSE -- Clustered
            BEGIN;
                DECLARE @ClusterVarKeyCols INT
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
                )
                SELECT @ClusterVarKeyCols = SUM(CASE
                            WHEN TYPE_NAME([ac].[user_type_id]) IN(''varchar'', ''nvarchar'', ''text'', ''image'', ''varbinary'')
                            THEN 1
                            ELSE 0
                        END),
                    @MaxClusterVarKeySize = SUM(CASE
                            WHEN TYPE_NAME([ac].[user_type_id]) IN(''varchar'', ''nvarchar'', ''text'', ''image'', ''varbinary'')
                            THEN CASE [ac].[max_length]
                                        WHEN -1
                                        THEN(4000 + 2) -- use same estimation as the query engine for max lenths
                                        ELSE COL_LENGTH(OBJECT_NAME([i].object_id), [ac].[name])
                                    END
                            ELSE 0
                        END), 
                    @ClusterNumFixedKeyCols = SUM(CASE
                            WHEN TYPE_NAME([ac].[user_type_id]) NOT IN(''varchar'', ''nvarchar'', ''text'', ''image'', ''varbinary'')
                            THEN 1
                            ELSE 0
                        END), 
                    @MaxClusterFixedKeySize = SUM(CASE
                            WHEN TYPE_NAME([ac].[user_type_id]) NOT IN(''varchar'', ''nvarchar'', ''text'', ''image'', ''varbinary'')
                            THEN COL_LENGTH(OBJECT_NAME([i].object_id), [ac].[name])
                            ELSE 0
                        END),
                    @ClusterNullCols = SUM(CAST([ac].[is_nullable] AS TINYINT))
                FROM [sys].[indexes] AS [i]
                    INNER JOIN [sys].[index_columns] AS [ic] ON [i].[index_id] = [ic].[index_id]
                        AND [ic].object_id = [i].object_id
                    INNER JOIN [sys].[all_columns] AS [ac] ON [ac].object_id = [ic].object_id
                        AND [ac].[column_id] = [ic].[column_id]
                WHERE [i].[type] = 1
                    AND [i].[object_id] = @ObjectID
                    AND [ac].[name] NOT IN (SELECT [name] FROM [NewIndexCol]);')
                SET @ParmDefinition = N'@IndexName SYSNAME, @ObjectID BIGINT, @ClusterVarKeyCols INT OUTPUT,
                    @MaxClusterVarKeySize INT OUTPUT, @ClusterNumFixedKeyCols INT OUTPUT,
                    @MaxClusterFixedKeySize INT OUTPUT, @ClusterNullCols INT OUTPUT';
                EXEC sp_executesql @Sql
                ,@ParmDefinition
                ,@IndexName
                ,@ObjectID
                ,@ClusterVarKeyCols OUTPUT
                ,@MaxClusterVarKeySize OUTPUT
                ,@ClusterNumFixedKeyCols OUTPUT
                ,@MaxClusterFixedKeySize OUTPUT
                ,@ClusterNullCols OUTPUT;

                -- Add counts from clustered index cols 
                SET @NumKeyCols = @NumKeyCols + (@ClusterVarKeyCols + @ClusterNumFixedKeyCols) + 1 --(+ 1 if the clustered index is nonunique)
                SET @FixedKeySize = @FixedKeySize + @MaxClusterFixedKeySize 
                SET @NumVariableKeyCols = @NumVariableKeyCols + @ClusterVarKeyCols + 1 --(+ 1 if the clustered index is nonunique)
                SET @MaxVarKeySize = @MaxVarKeySize + @MaxClusterVarKeySize + 4 --(+ 4 if the clustered index is nonunique)
                SET @NullCols = @NullCols + @ClusterNullCols;
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

        IF (@IncludedColumns IS NOT NULL)
            BEGIN;
                SELECT 'Not supported yet!';
                /* 
                Num_Leaf_Cols = Num_Key_Cols + number of included columns
                Fixed_Leaf_Size = Fixed_Key_Size + total byte size of fixed-length included columns
                Num_Variable_Leaf_Cols = Num_Variable_Key_Cols + number of variable-length included columns
                Max_Var_Leaf_Size = Max_Var_Key_Size + maximum byte size of variable-length included columns
                */
                RETURN;
            END;
        
        -- Account for data row locator
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
                    SELECT 'Not supported yet!';
                        /*
                        Num_Leaf_Cols = Num_Leaf_Cols + number of clustering key columns not in the set of nonclustered index key columns (+ 1 if the clustered index is nonunique)
                        Fixed_Leaf_Size = Fixed_Leaf_Size + number of fixed-length clustering key columns not in the set of nonclustered index key columns
                        Num_Variable_Leaf_Cols = Num_Variable_Leaf_Cols + number of variable-length clustering key columns not in the set of nonclustered index key columns (+ 1 if the clustered index is nonunique)
                        Max_Var_Leaf_Size = Max_Var_Leaf_Size + size in bytes of the variable-length clustering key columns not in the set of nonclustered index key columns (+ 4 if the clustered index is nonunique)
                        */
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
            @IndexSpaceUsed INT = 0;

        -- Calculate the number of non-leaf levels in the index
        SET @NonLeafLevels = CEILING(1 + LOG(@IndexRowsPerPage) * (@NumLeafPages / @IndexRowsPerPage));
        
        WHILE (@NonLeafLevels > 0)
            BEGIN
                SET @NumIndexPages = @NumIndexPages + (@NumLeafPages / (@IndexRowsPerPage ^ @NonLeafLevels));
                SET @NonLeafLevels = @NonLeafLevels - 1;
            END;
        
        -- Calculate size of the index
        SET @IndexSpaceUsed = 8192 * @NumIndexPages;

        /**************************************/
        /* 4. Total index and leaf space used */
        /**************************************/
        DECLARE @Total INT = 0;

        SET @Total = @LeafSpaceUsed + @IndexSpaceUsed;

        SELECT @Total AS [Total bytes used], @Total/1024 AS [Total kb used], @Total/1024.00/1024.00 AS [Total mb used];
    END;

    -- Remove hypothetical index
    EXEC sp_executesql @DropIndexSql;

END TRY
BEGIN CATCH;
    BEGIN;
        DECLARE @ErrorNumber INT = ERROR_NUMBER();
        DECLARE @ErrorLine INT = ERROR_LINE();
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();

        -- Remove hypothetical index
        EXEC sp_executesql @DropIndexSql;

        SET @ErrorMessage = CONCAT(QUOTENAME(OBJECT_NAME(@@PROCID)), ': ', @ErrorMessage);
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState) WITH NOWAIT;
    END;
END CATCH;
END

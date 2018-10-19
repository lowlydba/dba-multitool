DROP TABLE IF EXISTS #TempIndexes;
DROP TABLE IF EXISTS #IndexChecksum;
DROP TABLE IF EXISTS #DuplicateIndexes;
DROP TABLE IF EXISTS #OverlappingIndex;

DECLARE @IndexedColumns NVARCHAR(MAX) = N'';
DECLARE @IndexedColumnsInclude NVARCHAR(MAX) = N'';
DECLARE @Counter BIGINT = 1;
DECLARE @MAX BIGINT = 0;

select  ac.name AS [col_name]
		,row_number () OVER ( PARTITION BY ind.object_id, ind.index_id ORDER BY indc.index_column_id ) AS row_num
		,ind.index_id
		,ind.object_id
		,DENSE_RANK() over (order by ind.object_id, ind.index_id) AS [index_num]
		,indc.is_included_column
		,NULL AS [checksum]
		,NULL AS [checksum_incl]
		,ao.schema_id 
INTO #TempIndexes
from sys.indexes as [ind]
	INNER JOIN sys.index_columns AS [indc] ON [ind].[object_id] = [indc].[object_id] AND ind.index_id = indc.index_id
	INNER JOIN sys.all_columns as [ac] ON [ac].[column_id] = [indc].[column_id] and indc.[object_id] = ac.[object_id] 
	INNER JOIN sys.all_objects AS [ao] ON [ao].[object_id] = [ac].[object_id]
WHERE ao.is_ms_shipped = 0
order by ind.object_id

SELECT @Max = MAX(Index_num) FROM #TempIndexes

WHILE @Counter <= @Max 
BEGIN
	SET @IndexedColumns = N'';
	SET @IndexedColumnsInclude = N'';

	SELECT @IndexedColumns += CAST(col_name AS SYSNAME)
	FROM #TempIndexes
	WHERE is_included_column = 0
		AND index_num = @Counter
	ORDER BY row_num;

		SELECT @IndexedColumnsInclude += CAST(col_name AS SYSNAME)
	FROM #TempIndexes
		WHERE index_num = @Counter
	ORDER BY row_num;

		UPDATE #TempIndexes
		SET [checksum] = CHECKSUM(@IndexedColumns), checksum_incl = CHECKSUM(@IndexedColumnsInclude)
		WHERE index_num = @Counter;

	SET @COUNTER += 1;
END

SELECT DISTINCT object_id, index_id, [checksum], checksum_incl, [schema_id]
INTO #IndexChecksum
FROM #TempIndexes;

WITH MatchingChecksumInclude AS (
SELECT COUNT(*) AS [num_dup_indexes], [checksum_incl], object_id
from #IndexChecksum
GROUP BY [checksum_incl], object_id
HAVING COUNT(*) > 1)

SELECT N'Duplicate Indexes' AS [check_type]
		,N'INDEX' AS [obj_type]
		,QUOTENAME(DB_NAME()) AS [db_name]
		,QUOTENAME(SCHEMA_NAME([schema_id])) + '.' + QUOTENAME(OBJECT_NAME(ic.object_id)) + '.' + QUOTENAME(i.[name]) AS [object_name]
		,NULL AS [col_name]
		,'Indexes in group ' + CAST(DENSE_RANK() over (order by MatchingChecksumInclude.checksum_incl) AS VARCHAR(5)) + ' share the same indexed and included columns.' AS [message]
		,N'http://lowlydba.com/ExpressSQL/#' AS [ref_link]
		,ic.object_id
		,ic.index_id
INTO #DuplicateIndexes
FROM MatchingChecksumInclude
	INNER JOIN #IndexChecksum AS ic ON ic.object_id = MatchingChecksumInclude.object_id AND ic.checksum_incl = MatchingChecksumInclude.checksum_incl
	INNER JOIN sys.indexes AS [i] ON [i].[index_id] = ic.index_id AND i.object_id = ic.object_id;

WITH MatchingChecksum AS (
SELECT COUNT(*) AS [num_dup_indexes], [checksum], object_id
from #IndexChecksum
GROUP BY [checksum], object_id
HAVING COUNT(*) > 1)

SELECT N'Overlapping Indexes' AS [check_type]
		,N'INDEX' AS [obj_type]
		,QUOTENAME(DB_NAME()) AS [db_name]
		,QUOTENAME(SCHEMA_NAME([schema_id])) + '.' + QUOTENAME(OBJECT_NAME(ic.object_id)) + '.' + QUOTENAME(i.[name]) AS [object_name]
		,NULL AS [col_name]
		,'Indexes in group ' + CAST(DENSE_RANK() over (order by [MatchingChecksum].[checksum]) AS VARCHAR(5)) + ' share the same indexed columns.' AS [message]
		,N'http://lowlydba.com/ExpressSQL/#' AS [ref_link]
		,ic.object_id
		,ic.index_id
INTO #OverlappingIndex
FROM MatchingChecksum
	INNER JOIN #IndexChecksum AS ic ON ic.object_id = MatchingChecksum.object_id AND ic.checksum = MatchingChecksum.checksum
	INNER JOIN sys.indexes AS [i] ON [i].[index_id] = ic.index_id AND i.object_id = ic.object_id
WHERE NOT EXISTS (SELECT * FROM #DuplicateIndexes AS [di] WHERE [di].object_id = ic.object_id AND di.index_id = ic.index_id)

select * from #DuplicateIndexes
SELECT * FROM #OverlappingIndex
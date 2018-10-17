DROP TABLE IF EXISTS #TempIndexes

DECLARE @IndexedColumns NVARCHAR(MAX) = N'';
DECLARE @IndexedColumnsInclude NVARCHAR(MAX) = N'';
DECLARE @Counter BIGINT = 1;
DECLARE @MAX BIGINT = 0;

select ac.name AS [col_name], row_number () OVER ( PARTITION BY ind.object_id, ind.index_id ORDER BY indc.index_column_id ) AS row_num, ind.index_id, ind.name, ind.object_id
				, DENSE_RANK() over (order by ind.object_id, ind.index_id) AS [index_num]
				,indc.is_included_column
				,NULL AS [checksum]
				,NULL AS [checksum_incl]
INTO #TempIndexes
from sys.indexes as [ind]
	INNER JOIN sys.index_columns AS [indc] ON [ind].object_id = [indc].object_id AND ind.index_id = indc.index_id
	INNER JOIN sys.all_columns as [ac] ON [ac].[column_id] = [indc].[column_id] and indc.object_id = ac.object_id 
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

SELECT * FROM #TempIndexes

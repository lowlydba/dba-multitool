CREATE OR ALTER PROCEDURE dbo.sp_predindex
    @SchemaName SYSNAME,
    @TableName SYSNAME,
    @IndexColumns NVARCHAR(2048)
AS 
BEGIN

SET NOCOUNT ON;

/* Example:

    EXEC dbo.sp_predindex @SchemaName = 'dbo', @tableName = 'Marathon', @IndexColumns = 'racer_id, finish_time, is_disqualified';

*/

DECLARE @sql NVARCHAR(MAX);
DECLARE @QualifiedTable NVARCHAR(257) = CONCAT(QUOTENAME(@SchemaName), '.', QUOTENAME(@TableName));
DECLARE @IndexName SYSNAME = CONCAT('sp_predindex_hypothetical_index_', CAST(GETDATE() AS INT));
DECLARE @DropIndexSql NVARCHAR(MAX);
DECLARE @CreateIndex NVARCHAR(MAX);


--TODO: 
-- Validate columns all exist in table ?
-- Add EPs
-- Build unit tests
-- cleanup mode? 
-- output table to compare with other runs?


SET @DropIndexSql = CONCAT('DROP INDEX IF EXISTS', QUOTENAME(@IndexName), ' ON ', @QualifiedTable);
EXEC sp_executesql @DropIndexSql;

SET @CreateIndex = CONCAT(N'CREATE NONCLUSTERED INDEX ', QUOTENAME(@IndexName), ' ON ', @QualifiedTable, '(', @IndexColumns, ') WITH (STATISTICS_ONLY = -1)');
EXEC sp_executesql @CreateIndex;

SET @sql =  'DBCC SHOW_STATISTICS ("' + @QualifiedTable + '", ' + QUOTENAME(@IndexName) + ')'
EXEC sp_executesql @sql;

SET @DropIndexSql = CONCAT('DROP INDEX IF EXISTS', QUOTENAME(@IndexName), ' ON ', QUOTENAME(@QualifiedTable));
EXEC sp_executesql @DropIndexSql;

END


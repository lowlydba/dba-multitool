USE [master];
GO

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_SizeOptiMiser]'))
    BEGIN
		DROP PROCEDURE [dbo].[sp_SizeOptiMiser];
	END
GO

IF NOT EXISTS(SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_SizeOptiMiser]'))
    BEGIN
		EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[sp_SizeOptiMiser] AS';
    END;
GO

ALTER PROCEDURE [dbo].[sp_SizeOptiMiser] 
				@IndexNumThreshold INT = 7
WITH RECOMPILE
AS
	 BEGIN TRY
		  SET NOCOUNT ON;
		  
		  IF OBJECT_ID(N'tempdb..#results') IS NOT NULL
            BEGIN
                DROP TABLE #results;
            END;

        DECLARE @isExpress BIT= 0;
        DECLARE @getGreedy BIT= 0;
        DECLARE @hasSparse BIT= 0;
        DECLARE @version SMALLINT= 0;
        DECLARE @lastUpdated NVARCHAR(20)= '2018-06-25';
        DECLARE @fullVersion NVARCHAR(50)= (SELECT @@VERSION);
        DECLARE @checkSQL NVARCHAR(MAX)= N'';

		  /* Find edition */
        IF(CAST(SERVERPROPERTY('Edition') AS VARCHAR(50))) LIKE '%express%'
             SET @isExpress = 1;
		
		  /* Find Version */
        SET @version = (SELECT CAST(LEFT(CAST(SERVERPROPERTY('ProductVersion') AS NVARCHAR), CHARINDEX('.', CAST(SERVERPROPERTY('ProductVersion') AS NVARCHAR), 0)-1) AS INT));

		  /* Check for Sparse Columns feature */
        IF 1 = (SELECT COUNT(*) FROM sys.all_columns AS ac WHERE ac.name = 'is_sparse' AND OBJECT_NAME(ac.object_id) = 'all_columns')
             BEGIN
                 SET @hasSparse = 1;
             END;
		
		  /* Print info */
        PRINT 'sp_OptiMiser';
        PRINT '------------';
        PRINT '';
        PRINT 'Time:				 '+CAST(GETDATE() AS NVARCHAR(50));
        PRINT 'Express Edition:  '+CAST(@isExpress AS CHAR(1));
        PRINT 'SQL Major Version:'+CAST(@version AS VARCHAR(2));
        PRINT '@getGreedy: 		 '+CAST(@getGreedy AS CHAR(1));
        PRINT 'Sparse Columns:	 '+CAST(@hasSparse AS CHAR(1));
        PRINT '';
        PRINT 'Building results table...';

		  /*Build results table */

        CREATE TABLE #results
				([ID]			INT IDENTITY(1, 1) NOT NULL PRIMARY KEY,
				[check_num]		INT NOT NULL,
				[check_type]	NVARCHAR(50) NOT NULL,
				[db_name]		SYSNAME NOT NULL,
				[obj_type]		SYSNAME NOT NULL,
				[obj_name]		SYSNAME NOT NULL,
				[col_name]		SYSNAME NULL,
				[message]		NVARCHAR(500) NULL,
				[ref_link]		NVARCHAR(500) NULL);

		  /* Header row */
        INSERT INTO #results ([check_num], [check_type], [obj_type], [db_name], [obj_name], [col_name], [message], [ref_link])
        SELECT	0,
				N'Let''s do this',
				N'Vroom, vroom',
				N'beep boop',
				N'Off to the races!',
				N'Ready, set, go!',
				N'Last Updated '+ @lastUpdated,
				N'http://expressdb.io';

        PRINT 'Running size checks...';
        PRINT '';

		  /* Check 1: Did you mean to use a time based format? */
        PRINT 'Check 1 - Time based formats';
        BEGIN
             SET @checkSQL = 'USE [?]; INSERT INTO #results ([check_num], [check_type], [obj_type], [db_name], [obj_name], [col_name], [message], [ref_link])
							 SELECT 1, 
							 N''Data Formats'', 
							 N''USER_TABLE'', 
							 DB_NAME(),
							 QUOTENAME(SCHEMA_NAME(t.schema_id)) + ''.'' + QUOTENAME(t.name), 
							 QUOTENAME(c.name), 
							 N''Columns storing date or time should use a temporal specific data type, but this column is using '' + ty.name + ''.'', 
							 N''https://github.com/LowlyDBA/ExpressSQL/tree/master#time-based-formats''
							 FROM sys.columns as c
								 inner join sys.tables as t on t.object_id = c.object_id
								 inner join sys.types as ty on ty.user_type_id = c.user_type_id
							 WHERE c.is_identity = 0 --exclude identity cols
								 AND t.is_ms_shipped = 0 --exclude sys table
								 AND (c.name LIKE ''%date%'' OR c.name LIKE ''%time%'')
								 AND ty.name NOT IN (''datetime'', ''datetime2'', ''datetimeoffset'', ''date'', ''smalldatetime'', ''time'')
								 AND DB_ID() > 4;';
             EXEC sp_MSforeachdb
                  @checkSQL;
         END; --Check 1

		/* Check 2: Old School Variable Lengths (255/256) */
        PRINT 'Check 2 - Archaic varchar Lengths';
			BEGIN
				SET @checkSQL = 'USE [?]; 
									WITH archaic AS (
										SELECT	QUOTENAME(SCHEMA_NAME(t.schema_id)) + ''.'' + QUOTENAME(t.name) AS [obj_name],
												QUOTENAME(c.name) AS [col_name],
												N''Possible arbitrary variable length column in use. Is the '' + ty.name + '' length of '' + CAST (c.max_length / 2 AS varchar(10)) + '' based on requirements'' AS [message],
												N''https://goo.gl/uiltVb'' AS [ref_link]
										FROM sys.columns as c
											inner join sys.tables as t on t.object_id = c.object_id
											inner join sys.types as ty on ty.user_type_id = c.user_type_id
										WHERE c.is_identity = 0 --exclude identity cols
											AND t.is_ms_shipped = 0 --exclude sys table
											AND ty.name = ''NVARCHAR''
											AND c.max_length IN (510, 512)
										UNION
										SELECT	QUOTENAME(SCHEMA_NAME(t.schema_id)) + ''.'' + QUOTENAME(t.name), 
												QUOTENAME(c.name), 
												N''Possible arbitrary variable length column in use. Is the '' + ty.name + '' length of '' + CAST (c.max_length AS varchar(10)) + '' based on requirements'', 
												N''https://goo.gl/uiltVb''
										FROM sys.columns as c
											inner join sys.tables as t on t.object_id = c.object_id
											inner join sys.types as ty on ty.user_type_id = c.user_type_id
										WHERE c.is_identity = 0 --exclude identity cols
											AND t.is_ms_shipped = 0 --exclude sys table
											AND ty.name = ''VARCHAR''
											AND c.max_length IN (255, 256)
											AND DB_ID() > 4)

									INSERT INTO #results ([check_num], [check_type], [obj_type], [db_name], [obj_name], [col_name], [message], [ref_link])
									SELECT	2, 
											N''Data Formats'',
											N''USER_TABLE'',
											DB_NAME(),
											[obj_name],
											[col_name],
											[message],
											[ref_link]
									FROM [archaic];';
				EXEC sp_MSforeachdb @checkSQL;
			END; --Check 2
	
		/* Check 3: Mad MAX - Varchar(MAX) */
		PRINT 'Check 3: Mad MAX VARCHAR';
			BEGIN
				SET @checkSQL = 'USE [?]; INSERT INTO #results ([check_num], [check_type], [obj_type], [db_name], [obj_name], [col_name], [message], [ref_link])
								SELECT 3,	
									N''Mad NVARCHAR(MAX)'', 
									N''USER_TABLE'',
									DB_NAME(),
									QUOTENAME(SCHEMA_NAME(t.schema_id)) + ''.'' + QUOTENAME(t.name), 
									QUOTENAME(c.name), 
									N''Column is NVARCHAR(MAX) which allows very large row sizes. Consider a character limit.'', 
									N''https://goo.gl/uiltVb''
								FROM sys.columns as c
									 inner join sys.tables as t on t.object_id = c.object_id
									 inner join sys.types as ty on ty.user_type_id = c.user_type_id
								WHERE t.is_ms_shipped = 0 --exclude sys table
									 AND ty.[name] = ''nvarchar''
									 AND c.max_length = -1
									 AND DB_ID() > 4;';
				EXEC sp_MSforeachdb @checkSQL;
			END; --Check 3
		
		/* Check 4: User DB or model db  Growth set past 10GB - ONLY IF EXPRESS*/

        PRINT 'Check 4: Data file growth set past 10GB (EXPRESS)';
        IF(@isExpress = 1)
			BEGIN
                 SET @checkSQL = 'USE [?]; INSERT INTO #results ([check_num], [check_type], [obj_type], [db_name], [obj_name], [col_name], [message], [ref_link])
								 select 4, N''Database Growth'', 
												N''DATABASE'', 
												DB_NAME(),
												QUOTENAME(DB_NAME(database_id)), 
												NULL, 
												N''Database file '' + name + '' has a maximum growth set to '' + CASE 
																													WHEN max_size = -1 
																														THEN ''Unlimited''
																													WHEN max_size > 0
																														THEN CAST((max_size / 1024) * 8 AS VARCHAR(MAX))
																												END + '', which is over the user database maximum file size of 10GB.'', 
												''http://''
									 from sys.master_files mf
								 where (max_size > 1280000 OR max_size = -1) -- greater than 10GB or unlimited
									 AND [mf].[database_id] > 4
									 AND [mf].[data_space_id] > 0 -- limit doesn''t apply to log files;';
                 EXEC sp_MSforeachdb @checkSQL;
             END;
        ELSE
             BEGIN
                 PRINT 'Skipping check 4...';
             END;

		/* Check 5: User DB or model db growth set to % */
        PRINT 'Check 5: Data file growth set to %';
        BEGIN
			INSERT INTO #results ([check_num], [check_type], [obj_type], [db_name], [obj_name], [col_name], [message], [ref_link])
                SELECT 5,
                        N'Database Growth',
                        N'DATABASE',
						DB_NAME(),
                        QUOTENAME(DB_NAME(database_id)),
                        NULL,
                        N'Database file '+[mf].[name]+' has growth set to % instead of a fixed amount. This may grow quickly.',
                        'http://'
                FROM [sys].[master_files] AS [mf]
                WHERE [MF].[database_id] > 4 --Not a system DB
                        AND [mf].[is_percent_growth] = 1
                        AND [mf].[data_space_id] = 1; --ignore log files;
         END;

		/* Check 6: Do you really need Nvarchar*/
        PRINT 'Check 6: Use of NVARCHAR (EXPRESS)';
        IF(@isExpress = 1)
			BEGIN
				SET @checkSQL = 'USE [?]; INSERT INTO #results ([check_num], [check_type], [obj_type], [db_name], [obj_name], [col_name], [message], [ref_link])
												SELECT 6
														, N''Data Formats''
														, N''USER_TABLE''
														, DB_NAME()
														, QUOTENAME(SCHEMA_NAME([o].schema_id)) + ''.'' + QUOTENAME(OBJECT_NAME([o].object_id))
														, QUOTENAME([ac].[name])
														, N''nvarchar columns take 2x the space per char of varchar. Only use if you need Unicode characters.''
														, N''http://''
												FROM   [sys].[all_columns] AS [ac]
														INNER JOIN [sys].[types] AS [t] ON [t].[user_type_id] = [ac].
														[user_type_id]
														INNER JOIN [sys].[objects] AS [o] ON [o].object_id = [ac].object_id
												WHERE  [t].[name] = ''NVARCHAR''
														AND [o].[is_ms_shipped] = 0
														AND DB_ID() > 4;';
                EXEC sp_MSforeachdb @checkSQL;
             END;
        ELSE
            BEGIN
                PRINT 'Skipping check 6...';
            END;

		/* Check 7: BIGINT for identity values - sure its needed ?  - ONLY IF EXPRESS*/
        PRINT 'Check 7: BIGINT used for identity columns (EXPRESS)';
        IF(@isExpress = 1)
			BEGIN
                SET @checkSQL = 'USE [?]; INSERT INTO #results ([check_num], [check_type], [obj_type], [db_name], [obj_name], [col_name], [message], [ref_link])
												SELECT  7, 
														  N''Data Formats'', 
														  N''USER_TABLE'', 
														  DB_NAME(),
														  QUOTENAME(SCHEMA_NAME(t.schema_id)) + ''.'' + QUOTENAME(t.name), 
														  QUOTENAME(c.name), 
														  N''BIGINT used on IDENTITY column in SQL Express. If values will never exceed 2,147,483,647 use INT instead.'', 
														  N''https://goo.gl/uiltVb''
												 FROM sys.columns as c
													 inner join sys.tables as t on t.object_id = c.object_id
													 inner join sys.types as ty on ty.user_type_id = c.user_type_id
												 WHERE t.is_ms_shipped = 0 --exclude sys table
													 AND ty.name = ''BIGINT''
													 AND c.is_identity = 1
													 AND DB_ID() > 4;';
                EXEC sp_MSforeachdb @checkSQL;
            END;
		ELSE --Skip check 
            BEGIN
                PRINT 'Skipping check 7...';
            END;

		/* Check 8: Don't use FLOAT or REAL */
        PRINT 'Check 8: FLOAT or REAL data types';
			BEGIN
				SET @checkSQL = 'USE [?]; INSERT INTO #results ([check_num], [check_type], [obj_type], [db_name], [obj_name], [col_name], [message], [ref_link])
														  SELECT 8,
																	N''Data Formats'',
																	[o].[type_desc],
																	DB_NAME(),
																	QUOTENAME(SCHEMA_NAME(o.schema_id)) + ''.'' + QUOTENAME(o.name),
																	QUOTENAME(ac.name),
																	N''Best practice is to use DECIMAL/NUMERIC instead of '' + st.name + '' for non floating point math.'',
																	N''https://goo.gl/uiltVb''
														  FROM sys.all_columns AS ac
																 INNER JOIN sys.objects AS o ON o.object_id = ac.object_id
																 INNER JOIN sys.systypes AS st ON st.xtype = ac.system_type_id
														  WHERE st.name IN(''FLOAT'', ''REAL'')
																 AND o.type_desc = ''USER_TABLE''
																 AND DB_ID() > 4;'
                EXEC sp_MSforeachdb @checkSQL;
			END;

		/* Check 9: Don't use deprecated values (NTEXT, TEXT, IMAGE) */
        PRINT 'Check 9: Deprecated data types';
			BEGIN
				SET @checkSQL = 'USE [?]; INSERT INTO #results ([check_num], [check_type], [obj_type], [db_name], [obj_name], [col_name], [message], [ref_link])
											SELECT 9,
												   N''Data Formats'',
												   DB_NAME(),
												   [o].[type_desc],
												   QUOTENAME(SCHEMA_NAME(o.schema_id)) + ''.'' + QUOTENAME(o.name),
												   QUOTENAME(ac.name),
												   N''Deprecated data type in use: '' + st.name + ''.'',
												   N''https://goo.gl/u9SgEj''
											FROM sys.all_columns AS ac
												 INNER JOIN sys.objects AS o ON o.object_id = ac.object_id
												 INNER JOIN sys.systypes AS st ON st.xtype = ac.system_type_id
											WHERE st.name IN(''NEXT'', ''TEXT'', ''IMAGE'')
												 AND o.type_desc = ''USER_TABLE''
												 AND DB_ID() > 4;'
				EXEC sp_MSforeachdb @checkSQL;
			END;

		/* Check 10: Non-default fill factor */
        PRINT 'Check 10: Non-default fill factor (EXPRESS)';
        IF(@isExpress = 1)
			BEGIN
                SET @checkSQL = 'USE [?]; INSERT INTO #results ([check_num], [check_type], [obj_type], [db_name], [obj_name], [col_name], [message], [ref_link])
											SELECT 10,
												   N''Fill Factor'',
												   DB_NAME(),
												   N''INDEX'',
												   QUOTENAME(SCHEMA_NAME([o].[schema_id])) + ''.'' + QUOTENAME([o].[name]) + ''.'' + QUOTENAME([i].[name]),
												   NULL,
												   N''Non-default fill factor on this index. Not inherently bad, but will increase table size more quickly.'',
												   N''http://''
											FROM [sys].[indexes] AS [i]
												 INNER JOIN [sys].[objects] AS [o] ON [o].[object_id] = [i].[object_id]
											WHERE [i].[fill_factor] NOT IN(0, 100)
													AND DB_ID() > 4;'
				EXEC sp_MSforeachdb @checkSQL;
            END;
        ELSE --Skip check
            BEGIN
				PRINT 'Skipping check 10...';
            END;

		/* Check 11: Questionable number of indexes */
        PRINT 'Check 11: Too many indexes';
        BEGIN
            SET @checkSQL = 'USE [?]; INSERT INTO #results ([check_num], [check_type], [obj_type], [db_name], [obj_name], [col_name], [message], [ref_link])
										SELECT 11,
											   N''Lotsa Indexes'',
											   N''INDEX'',
											   DB_NAME(),
											   QUOTENAME(SCHEMA_NAME(t.schema_id)) + ''.'' + QUOTENAME(t.name),
											   NULL,
											   ''There are '' + CAST(COUNT(DISTINCT(i.index_id)) AS VARCHAR) + '' indexes on this table taking up '' + CAST(CAST(SUM(s.[used_page_count]) * 8 / 1024.00 AS DECIMAL(10, 2)) AS VARCHAR) + '' MB of space.'',
											   ''http''
										FROM sys.indexes AS i
											 INNER JOIN sys.tables AS t ON i.object_id = t.object_id
											 INNER JOIN sys.dm_db_partition_stats AS s ON s.object_id = i.object_id
																				AND s.index_id = i.index_id
										WHERE t.is_ms_shipped = 0 --exclude sys table
											  AND i.type_desc = ''NONCLUSTERED'' --exclude clustered indexes from count
											  AND DB_ID() > 4
										GROUP BY t.name,
												 t.schema_id
										HAVING COUNT(DISTINCT(i.index_id)) > ' + CAST(@IndexNumThreshold AS VARCHAR(10)) + ';'
			EXEC sp_MSforeachdb @checkSQL;
         END;

		/* Check 12: Should sparse columns be used? */
		/* https://docs.microsoft.com/en-us/sql/relational-databases/tables/use-sparse-columns?view=sql-server-2017 */
        PRINT 'Check 12: Sparse column eligibility';
			IF @hasSparse = 1
				BEGIN
					IF OBJECT_ID('tempdb..#SparseTypes') IS NOT NULL
                        BEGIN;
                            DROP TABLE [#SparseTypes];
                        END;
                    IF OBJECT_ID('tempdb..#Stats') IS NOT NULL
                        BEGIN;
                            DROP TABLE [#Stats];
                        END;
                    IF OBJECT_ID('tempdb..#StatsHeaderStaging') IS NOT NULL
                        BEGIN;
                            DROP TABLE [#StatsHeaderStaging];
                        END;
                    IF OBJECT_ID('tempdb..#StatHistogramStaging') IS NOT NULL
                        BEGIN;
                            DROP TABLE [#StatHistogramStaging];
                        END;
	
					CREATE TABLE #SparseTypes (
							[ID] INT IDENTITY(1,1) NOT NULL,
							[name] VARCHAR(20),
							[user_type_ID] INT,
							[scale] TINYINT NULL,
							[precision] TINYINT NOT NULL,
							[threshold_null_perc] TINYINT NOT NULL);

					CREATE CLUSTERED INDEX cidx_#sparsetypes ON #SparseTypes([ID]);

					/*	Reference values for when it makes sense to use the sparse feature based on 40% minimum space savings
						including if those recommendations change based on scale / precision. Conservative estimates are used
						when a column is in between the high and low values in the table.										*/ 	
					INSERT INTO #SparseTypes ([name], [user_type_ID], [scale], [precision], [threshold_null_perc])
					VALUES	('BIT',104, 0,0, 98),
							('TINYINT',48, 0,0, 86),
							('SMALLINT',52, 0,0, 76),
							('INT',56, 0,0, 64),
							('BIGINT',127, 0,0, 52),
							('REAL',59, 0,0, 64),
							('FLOAT',62, 0,0, 52),
							('SMALLMONEY',122, 0,0, 64),
							('MONEY',60, 0,0, 52),
							('SMALLDATETIME',58, 0,0, 64),
							('DATETIME',61, 0,0, 52),
							('UNIQUEIDENTIFIER',36, 0,0, 43),
							('DATE',40, 0,0, 69),
							('DATETIME2',42, 0,0, 57),
							('DATETIME2',42, 7,0, 52),
							('TIME',41, 0,0, 69),
							('TIME',41, 7,0, 60),
							('DATETIMEOFFSET',43, 0,0, 52),
							('DATETIMEOFFSET',43, 7,0, 49),
							('VARCHAR',167, 0,0, 60),
							('CHAR',175, 0,0, 60),
							('NVARCHAR',231, 0,0, 60),
							('NCHAR',239, 0,0, 60),
							('VARBINARY',165, 0,0, 60),
							('BINARY',173, 0,0, 60),
							('XML',241, 0,0, 60),
							('HIERARCHYID',128, 0,0, 60),
							('DECIMAL', 106, NULL, 1, 60), 
							('DECIMAL', 106, NULL, 38, 42), 
							('NUMERIC', 108, NULL, 1, 60), 
							('NUMERIC', 108, NULL, 38, 42);

					CREATE TABLE #StatsHeaderStaging (
						 [name] SYSNAME 
						,[updated] DATETIME2(0)
						,[rows] BIGINT
						,[rows_sampled] BIGINT
						,[steps] INT
						,[density] DECIMAL(6,3)
						,[average_key_length] DECIMAL(5,2)
						,[string_index] VARCHAR(10)
						,[filter_expression] nvarchar(max)
						,[unfiltered_rows] BIGINT);

					CREATE TABLE #Stats (
						 [stats_id] INT IDENTITY(1,1)
						,[db_name] SYSNAME
						,[stat_name] SYSNAME 
						,[stat_updated] DATETIME2(0)
						,[rows] BIGINT
						,[rows_sampled] BIGINT
						,[schema_name] SYSNAME
						,[table_name] SYSNAME NULL
						,[col_name] SYSNAME NULL
						,[eq_rows] BIGINT NULL
						,[null_perc] AS CAST([eq_rows] AS DECIMAL (38,2)) /[rows] * 100
						,[threshold_null_perc] SMALLINT);

					CREATE CLUSTERED INDEX cidx_#stats ON #Stats([stats_id]);

					CREATE TABLE #StatHistogramStaging (
						 [range_hi_key] NVARCHAR(MAX)
						,[range_rows] BIGINT
						,[eq_rows] DECIMAL(38,2)
						,[distinct_range_rows] BIGINT
						,[avg_range_rows] BIGINT);

					DECLARE @db_name SYSNAME;
					DECLARE @tempStatSQL NVARCHAR(MAX) = N'';
					DECLARE @statSQL NVARCHAR(MAX) = 
						N'	USE ?;
							BEGIN
								DECLARE	@schemaName SYSNAME,
										@tableName SYSNAME, 
										@statName SYSNAME, 
										@colName SYSNAME, 
										@threshold_null_perc SMALLINT;

								DECLARE @DBCCSQL NVARCHAR(MAX) = N'''';
								DECLARE @DBCCStatSQL NVARCHAR(MAX) = N'''';
								DECLARE @DBCCHistSQL NVARCHAR(MAX) = N'''';

								DECLARE [DBCC_Cursor] CURSOR LOCAL FAST_FORWARD
								FOR SELECT DISTINCT	  sch.name	AS [schema_name]
													, t.name	AS [table_name]
													, s.name	AS [stat_name]
													, ac.name	AS [col_name]
													, threshold_null_perc 
									FROM [sys].[stats] AS [s] 
										INNER JOIN [sys].[stats_columns] AS [sc] on sc.stats_id = s.stats_id
										INNER JOIN [sys].[tables] AS [t] on t.object_id = s.object_id
										INNER JOIN [sys].[schemas] AS [sch] on sch.schema_id = t.schema_id
										INNER JOIN [sys].[all_columns] AS [ac] on ac.column_id = sc.column_id
																AND [ac].[object_id] = [t].[object_id]
																AND [ac].[object_id] = [sc].[object_id]
										INNER JOIN [sys].[types] AS [typ] ON [typ].[user_type_id] = [ac].[user_type_id]
										LEFT JOIN [sys].[indexes] AS [i] ON i.object_id = t.object_id
																AND i.name = s.name
										LEFT JOIN [sys].[index_columns] AS [ic] ON [ic].[object_id] = [i].[object_id]
																AND [ic].[column_id] = [ac].[column_id]
																AND ic.index_id = i.index_id
										INNER JOIN [#SparseTypes] AS [st] ON [st].[user_type_id] = [typ].[user_type_id]
																AND (typ.name NOT IN (''DECIMAL'', ''NUMERIC'', ''DATETIME2'', ''TIME'', ''DATETIMEOFFSET''))
																OR (typ.name IN (''DECIMAL'', ''NUMERIC'') AND st.precision = ac.precision AND st.precision = 1)
																OR (typ.name IN (''DECIMAL'', ''NUMERIC'') AND ac.precision > 1 AND st.precision = 38)
																OR (typ.name IN (''DATETIME2'', ''TIME'', ''DATETIMEOFFSET'') AND st.scale = ac.scale AND st.scale = 0)
																OR (typ.name IN (''DATETIME2'', ''TIME'', ''DATETIMEOFFSET'') AND ac.scale > 0 AND st.scale = 7)
									WHERE [sc].[stats_column_id] = 1 
										AND [s].[has_filter] = 0 
										AND [s].[no_recompute] = 0 
										AND [ac].[is_nullable] = 1 
										AND [s].[is_temporary] = 0 
										AND [ic].[index_column_id] IN (NULL, 1)
										AND [i].[type_desc] IN (NULL, ''NONCLUSTERED'')
								
								OPEN [DBCC_Cursor];

								FETCH NEXT FROM [DBCC_Cursor]
								INTO @schemaName, @tableName, @statName, @colName, @threshold_null_perc;

								WHILE @@FETCH_STATUS = 0
									BEGIN;
										/* Build DBCC statistics queries */
										SET @DBCCSQL = N''DBCC SHOW_STATISTICS('''''' + @schemaName + ''.'' + @tableName + '''''', '''''' + @statName + '''''')'';
										SET @DBCCStatSQL = @DBCCSQL + '' WITH STAT_HEADER;'';
										SET @DBCCHistSQL = @DBCCSQL + '' WITH HISTOGRAM;'';

										/* Stat Header */
										INSERT INTO #StatsHeaderStaging 
										EXEC sp_executeSQL @DBCCStatSQL;

										/* Histogram */
										INSERT INTO #StatHistogramStaging 
										EXEC sp_executesql @DBCCHistSQL;

										INSERT INTO #Stats  
										SELECT	  DB_NAME()
												, [head].[name]
												, [head].[updated]
												, [head].[rows]
												, [head].[rows_Sampled]
												, @schemaName
												, @tableName
												, @colName
												, [hist].[eq_rows]
												, @threshold_null_perc
										FROM #StatsHeaderStaging head 
											CROSS APPLY #StatHistogramStaging hist
										WHERE hist.RANGE_HI_KEY IS NULL
											AND hist.eq_rows > 0
											AND head.Unfiltered_rows > 0
											AND head.rows > 1000;

										TRUNCATE TABLE #StatsHeaderStaging; 
										TRUNCATE TABLE #StatHistogramStaging;

										FETCH NEXT FROM DBCC_Cursor 
										INTO @schemaName, @tableName, @statName, @colName, @threshold_null_perc;
									END;
								CLOSE [DBCC_Cursor];
								DEALLOCATE [DBCC_Cursor];
							END;'

					DECLARE [DB_Cursor] CURSOR LOCAL FAST_FORWARD
					FOR SELECT QUOTENAME([name])
						FROM [sys].[databases]
						WHERE [database_id] > 4;

					OPEN [DB_Cursor];

					FETCH NEXT FROM [DB_Cursor]
					INTO @db_name

					/* Run stat query for each database */
					WHILE @@FETCH_STATUS = 0
						BEGIN
							SET @tempStatSQL = REPLACE(@statSQL, N'?', @db_name);

							EXEC sp_executeSQL @tempStatSQL;

							FETCH NEXT FROM [DB_Cursor]
							INTO @db_name;
						END;
					CLOSE [DB_Cursor];
					DEALLOCATE [DB_Cursor];
					
					INSERT INTO #results ([check_num], [check_type], [obj_type], [db_name], [obj_name], [col_name], [message], [ref_link])
					SELECT	12, 
							N'Feature', 
							N'USER_TABLE', 
							[db_name], 
							QUOTENAME([schema_name]) + '.' + QUOTENAME([table_name]), 
							QUOTENAME([col_name]), 
							N'Candidate for converting to a space-saving sparse column based on NULL distribution.', 
							N'http://'
					FROM #stats
					WHERE [null_perc] >= [threshold_null_perc];
				END;
			ELSE 
				BEGIN;
					PRINT 'Skipping check 12 - sparse columns not available in this version.'
				END;

		/* Check 13: numeric or decimal with 0 scale */
        PRINT 'Check 13: NUMERIC or DECIMAL with scale of 0';
        BEGIN
			SET @checkSQL = 'USE [?]; INSERT INTO #results ([check_num], [check_type], [obj_type], [db_name], [obj_name], [col_name], [message], [ref_link])
									SELECT 13,
										   N''Data Formats'',
										   DB_NAME(),
										   [o].[type_desc],
										   QUOTENAME(SCHEMA_NAME(o.schema_id)) + ''.'' + QUOTENAME(o.name),
										   QUOTENAME(ac.name),
										   N''Column is '' + UPPER(st.name) + ''('' + CAST(ac.precision AS VARCHAR) + '','' + CAST(ac.scale AS VARCHAR) + '')'' +'' . Consider using an INT variety for space reduction since the scale is 0.'',
										   N''https://goo.gl/agh5CA''
									FROM sys.objects AS o
										 INNER JOIN sys.all_columns AS ac ON ac.object_id = o.object_id
										 INNER JOIN sys.systypes AS st ON st.xtype = ac.system_type_id
									WHERE ac.scale = 0
										  AND st.name IN(''DECIMAL'', ''NUMERIC'')
										  AND DB_ID() > 4;'
			EXEC sp_MSforeachdb @checkSQL;
         END;
		
		/* Wrap it up */
        SELECT * FROM #results;

		PRINT '';
        PRINT 'Done!';

	END TRY
	 
	BEGIN CATCH;
		BEGIN
			DECLARE @ErrorNumber INT = ERROR_NUMBER();
			DECLARE @ErrorLine INT = ERROR_LINE();
			DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
			DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
			DECLARE @ErrorState INT = ERROR_STATE();
 
			PRINT 'Actual error number: ' + CAST(@ErrorNumber AS VARCHAR(10));
			PRINT 'Actual line number: ' + CAST(@ErrorLine AS VARCHAR(10));
 
			RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
		END
	 END CATCH;
GO


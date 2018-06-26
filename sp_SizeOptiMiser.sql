USE [master];
GO
IF EXISTS
(
    SELECT *
    FROM sys.objects
    WHERE object_id = OBJECT_ID(N'[dbo].[sp_SizeOptiMiser]')
          AND type IN(N'P', N'PC')
)
    DROP PROCEDURE [dbo].[sp_SizeOptiMiser];
GO
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
IF NOT EXISTS
(
    SELECT *
    FROM sys.objects
    WHERE object_id = OBJECT_ID(N'[dbo].[sp_SizeOptiMiser]')
          AND type IN(N'P', N'PC')
)
    BEGIN
        EXEC dbo.sp_executesql
             @statement = N'CREATE PROCEDURE [dbo].[sp_SizeOptiMiser] AS';
    END;
GO
ALTER PROCEDURE [dbo].[sp_SizeOptiMiser] @IndexNumThreshold INT = 7,
                                         @IndexSizeMB       INT = 100
WITH RECOMPILE
AS
	 BEGIN
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
        IF 1 = (	  SELECT COUNT(*)
						  FROM sys.all_columns AS ac
						  WHERE ac.name = 'is_sparse'
									 AND OBJECT_NAME(ac.object_id) = 'all_columns')
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
				([ID]         INT IDENTITY(1, 1) NOT NULL PRIMARY KEY,
				[check_num]  INT NOT NULL,
				[check_type] NVARCHAR(50) NOT NULL,
				[obj_type]   SYSNAME NOT NULL,
				[obj_name]   SYSNAME NOT NULL,
				[col_name]   SYSNAME NULL,
				[message]    NVARCHAR(500) NULL,
				[ref_link]   NVARCHAR(500) NULL);

		  /* Header row */
        INSERT INTO #results
                SELECT '0',
                       'Let''s do this',
                       'Vroom, vroom',
                       'Off to the races!',
                       'Ready, set, go!',
                       'Last Updated '+ @lastUpdated,
                       'http://expressdb.io';

        PRINT 'Running size checks...';
        PRINT '';

		  /* Check 1: Did you mean to use a time based format? */
        PRINT 'Check 1 - Time based formats';
        BEGIN
             SET @checkSQL = 'USE [?]; INSERT INTO #results
							 SELECT 1, 
							 N''Data Formats'', 
							 N''USER_TABLE'', 
							 QUOTENAME(SCHEMA_NAME(t.schema_id)) + ''.'' + QUOTENAME(t.name), 
							 QUOTENAME(c.name), 
							 N''Columns storing date or time should use a temporal specific data type, but this column is using '' + ty.name + ''.'', 
							 N''https://goo.gl/uiltVb''
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
				SET @checkSQL = 'USE [?]; INSERT INTO #results 
								  SELECT	  2, 
												N''Data Formats'', 
												N''USER_TABLE'', 
												QUOTENAME(SCHEMA_NAME(t.schema_id)) + ''.'' + QUOTENAME(t.name), QUOTENAME(c.name), 
												N''Possible arbitrary variable length column in use. Is the '' + ty.name + '' length of '' + CAST (c.max_length / 2 AS varchar(10)) + '' based on requirements'', 
												N''https://goo.gl/uiltVb''
								  FROM sys.columns as c
									  inner join sys.tables as t on t.object_id = c.object_id
									  inner join sys.types as ty on ty.user_type_id = c.user_type_id
								  WHERE c.is_identity = 0 --exclude identity cols
									  AND t.is_ms_shipped = 0 --exclude sys table
									  AND ty.name = ''NVARCHAR''
									  AND c.max_length IN (510, 512)
								  UNION
								  SELECT 2, 
										  N''Data Formats'', 
										  N''USER_TABLE'', 
										  QUOTENAME(SCHEMA_NAME(t.schema_id)) + ''.'' + QUOTENAME(t.name), QUOTENAME(c.name), 
										  N''Possible arbitrary variable length column in use. Is the '' + ty.name + '' length of '' + CAST (c.max_length AS varchar(10)) + '' based on requirements'', 
										  N''https://goo.gl/uiltVb''
								  FROM sys.columns as c
									  inner join sys.tables as t on t.object_id = c.object_id
									  inner join sys.types as ty on ty.user_type_id = c.user_type_id
								  WHERE c.is_identity = 0 --exclude identity cols
									  AND t.is_ms_shipped = 0 --exclude sys table
									  AND ty.name = ''VARCHAR''
									  AND c.max_length IN (255, 256)
									  AND DB_ID() > 4;';
				EXEC sp_MSforeachdb @checkSQL;
			END; --Check 2
	
		/* Check 3: Mad MAX - Varchar(MAX) */
		PRINT 'Check 3: Mad MAX VARCHAR';
			BEGIN
				SET @checkSQL = 'USE [?]; INSERT INTO #results
								SELECT 3, N''Mad NVARCHAR(MAX)'', ''USER_TABLE'', QUOTENAME(SCHEMA_NAME(t.schema_id)) + ''.'' + QUOTENAME(t.name), QUOTENAME(c.name), 
										  N''Column is NVARCHAR(MAX) which allows very large row sizes. Consider a character limit.'', N''https://goo.gl/uiltVb''
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
                 SET @checkSQL = 'USE [?]; INSERT INTO #results 
								 select 4, N''Database Growth'', 
												N''DATABASE'', 
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
			INSERT INTO #results
                SELECT 5,
                        N'Database Growth',
                        N'DATABASE',
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
				SET @checkSQL = 'USE [?]; INSERT INTO #results
												SELECT 6
														, N''Data Formats''
														, N''USER_TABLE''
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
                SET @checkSQL = 'USE [?]; INSERT INTO #results
												SELECT  7, 
														  N''Data Formats'', 
														  N''USER_TABLE'', 
														  QUOTENAME(SCHEMA_NAME(t.schema_id)) + ''.'' + QUOTENAME(t.name), QUOTENAME(c.name), 
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
				SET @checkSQL = 'USE [?]; INSERT INTO #results
														  SELECT 8,
																	N''Data Formats'',
																	o.type_desc,
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
				SET @checkSQL = 'USE [?]; INSERT INTO #results
											SELECT 9,
												   N''Data Formats'',
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
                SET @checkSQL = 'USE [?]; INSERT INTO #results
											SELECT 10,
												   N''Fill Factor'',
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
            SET @checkSQL = 'USE [?]; INSERT INTO #results
										SELECT 11,
											   N''Lotsa Indexes'',
											   N''INDEX'',
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
                     IF OBJECT_ID('tempdb..##SparseTypes') IS NOT NULL
                        BEGIN
                            DROP TABLE [##SparseTypes];
                        END;
                    IF OBJECT_ID('tempdb..##Stats') IS NOT NULL
                        BEGIN
                            DROP TABLE [##Stats];
                        END;
                    IF OBJECT_ID('tempdb..##StatsHeaderStaging') IS NOT NULL
                        BEGIN
                            DROP TABLE [##StatsHeaderStaging];
                        END;
                    IF OBJECT_ID('tempdb..##StatHistogramStaging') IS NOT NULL
                        BEGIN
                            DROP TABLE [##StatHistogramStaging];
                        END;

					CREATE TABLE [##SparseTypes]
							([ID]                  INT IDENTITY(1, 1) NOT NULL,
							 [data_type]           VARCHAR(50) COLLATE DATABASE_DEFAULT NOT NULL,
							 [scale]               TINYINT NULL,
							 [precision]           TINYINT NOT NULL,
							 [threshold_null_perc] TINYINT
							);
					CREATE TABLE [##StatsHeaderStaging]
					([Name]               SYSNAME,
						[Updated]            DATETIME2(0),
						[Rows]               BIGINT,
						[Rows Sampled]       BIGINT,
						[Steps]              INT,
						[Density]            DECIMAL(6, 3),
						[Average key length] DECIMAL(5, 2),
						[String index]       VARCHAR(10),
						[Filter Expression]  NVARCHAR(MAX),
						[Unfiltered_Rows]    BIGINT
					);
					CREATE TABLE [##Stats]
					([stat_name]          SYSNAME,
						[Updated]            DATETIME2(0),
						[Rows]               BIGINT,
						[Rows Sampled]       BIGINT,
						[Steps]              INT,
						[Density]            DECIMAL(6, 3),
						[Average key length] DECIMAL(5, 2),
						[String index]       VARCHAR(10),
						[Filter Expression]  NVARCHAR(MAX),
						[Unfiltered_Rows]    DECIMAL(38, 2),
						[schema_name]        SYSNAME,
						[table_name]         SYSNAME NULL,
						[col_name]           SYSNAME NULL,
						[sparse_type_id]     INT,
						[eq_rows]            BIGINT NULL,
						[null_perc] AS [eq_rows] / [Unfiltered_Rows] * 100
					);
					CREATE TABLE [##StatHistogramStaging]
					([RANGE_HI_KEY]        NVARCHAR(MAX),
						[RANGE_ROWS]          BIGINT,
						[EQ_ROWS]             DECIMAL(38, 2),
						[DISTINCT_RANGE_ROWS] BIGINT,
						[AVG_RANGE_ROWS]      BIGINT
					);
 
					INSERT INTO [##SparseTypes]( [data_type], [scale], [precision], [threshold_null_perc] )
								VALUES( 'bit', 0, 0, 98 ), 
								( 'tinyint', 0, 0, 86 ), 
								( 'smallint', 0, 0, 76 ), 
								( 'int', 0, 0, 64 ), 
								( 'bigint', 0, 0, 52 ), 
								( 'real', 0, 0, 64 ), 
								( 'float', 0, 0, 52 ), 
								( 'smallmoney', 0, 0, 64 ), 
								( 'money', 0, 0, 52 ), 
								( 'smalldatetime', 0, 0, 64 ), 
								( 'datetime', 0, 0, 52 ), 
								( 'uniqueidentifier', 0, 0, 43 ), 
								( 'date', 0, 0, 69 ), 
								( 'datetime2', 0, 0, 57 ), 
								( 'datetime2', 7, 0, 52 ), 
								( 'time', 0, 0, 69 ), 
								( 'time', 7, 0, 60 ), 
								( 'datetimeoffset', 0, 0, 52 ), 
								( 'datetimeoffset', 7, 0, 49 ), 
								( 'decimal', 0, 1, 60 ), 
								( 'decimal', 0, 38, 42 ), 
								( 'numeric', 0, 1, 60 ), 
								( 'numeric', 0, 38, 42 ), 
								( 'varchar', 0, 0, 60 ), 
								( 'char', 0, 0, 60 ),
								( 'nvarchar', 0, 0, 60 ), 
								( 'nchar', 0, 0, 60 ), 
								( 'varbinary', 0, 0, 60 ), 
								( 'binary', 0, 0, 60 ), 
								( 'xml', 0, 0, 60 ), 
								( 'hierarchyid', 0, 0, 60 );

					SET @checkSQL = 'USE [?]; 

									IF (DB_ID() > 4)
										BEGIN; 

											DECLARE @statSQL NVARCHAR(MAX)= N'';
											
											SELECT @statSQL = @statSQL+''INSERT INTO #StatsHeaderStaging EXEC sp_executesql N''''''DBCC SHOW_STATISTICS(''''''+[sch].[name]+''.''+[t].[name]+'''''', ''''''+[s].[name]+'''''') WITH STAT_HEADER, NO_INFOMSGS ''''''; 
												INSERT INTO #StatHistogramStaging EXEC sp_executesql N''''''DBCC SHOW_STATISTICS(''''''+[sch].[name]+''.''+[t].[name]+'''''', ''''''+[s].[name]+'''''') WITH HISTOGRAM, NO_INFOMSGS '''''';
												INSERT INTO ##Stats  SELECT head.*, ''''+[sch].[name]+'''', ''''+[t].[name]+'''', ''''+[ac].[name]+'''', ''''+CAST([st].[id] AS VARCHAR)+'''', hist.EQ_ROWS
												FROM #StatsHeaderStaging head 
													CROSS APPLY #StatHistogramStaging hist
												WHERE hist.RANGE_HI_KEY IS NULL
													AND hist.eq_rows > 0
													AND head.Unfiltered_rows > 0; 
											
												TRUNCATE TABLE #StatsHeaderStaging; 
												TRUNCATE TABLE #StatHistogramStaging;''
											FROM [sys].[stats] AS [s]
												  INNER JOIN [sys].[stats_columns] AS [sc] ON [sc].[stats_id] = [s].[stats_id]
												  INNER JOIN [sys].[tables] AS [t] ON [t].object_id = [s].object_id
												  INNER JOIN [sys].[schemas] AS [sch] ON [sch].schema_id = [t].schema_id
												  INNER JOIN [sys].[all_columns] AS [ac] ON [ac].[column_id] = [sc].[column_id]
																							AND [ac].object_id = [t].object_id
																							AND [ac].object_id = [sc].object_id
												  INNER JOIN [sys].[types] AS [typ] ON [typ].[user_type_id] = [ac].[user_type_id]
												  LEFT JOIN [sys].[indexes] AS [i] ON [i].object_id = [t].object_id
																					  AND [i].[name] = [s].[name]
												  LEFT JOIN [sys].[index_columns] AS [ic] ON [ic].object_id = [i].object_id
																							 AND [ic].[column_id] = [ac].[column_id]
																							 AND [ic].[index_id] = [i].[index_id]
												  INNER JOIN [##SparseTypes] AS [st] ON [st].[data_type] = [typ].[name] COLLATE DATABASE_DEFAULT
																					   AND ([typ].[name] NOT IN(''decimal'', ''numeric'', ''datetime2'', ''time'', ''datetimeoffset'')
																							OR [typ].[name] IN(''decimal'', ''numeric'')
																							AND [st].[precision] = [ac].[precision]
																							AND [st].[precision] = 1
																							OR [typ].[name] IN(''decimal'', ''numeric'')
																							AND [ac].[precision] > 1
																							AND [st].[precision] = 38
																							OR [typ].[name] IN(''datetime2'', ''time'', ''datetimeoffset'')
																							AND [st].[scale] = [ac].[scale]
																							AND [st].[scale] = 0
																							OR [typ].[name] IN(''datetime2'', ''time'', ''datetimeoffset'')
																							AND [ac].[scale] > 0
																							AND [st].[scale] = 7)
											WHERE [typ].[name] IN(''datetime2'', ''time'', ''datetimeoffset'')
												  AND [sc].[stats_column_id] = 1 --Only first cols are good for getting histogram info
												  AND [s].[has_filter] = 0 --Can''t trust filtered statistics
												  AND [s].[no_recompute] = 0 --Can''t trust out of date statistics
												  AND [ac].[is_nullable] = 1 -- Must be nullable!
												  AND [s].[is_temporary] = 0
												  AND ([ic].[index_column_id] IS NULL
													   OR [ic].[index_column_id] = 1)
												  AND [i].[type_desc] NOT LIKE ''%COLUMNSTORE%''; --Columnstore doesn''t have histograms
												SELECT @statSQL;

											 EXEC sp_executesql @statSQL;
											 INSERT INTO #results
													SELECT 12,
														   ''Space Features'',
														   ''USER_TABLE'',
														   [table_name],
														   [col_name],
														   ''Column is a candidate for becoming sparse to reduce size based on the frequency of NULL values.'',
														   ''http://''
													FROM [##Stats] AS [stat]
														 INNER JOIN [##SparseTypes] AS [st] ON [st].[ID] = [stat].[sparse_type_id]
													WHERE [stat].[null_perc] >= [st].[threshold_null_perc];
									END'
					EXEC sp_MSforeachdb @checkSQL
         END;

		/* Check 13: numeric or decimal with 0 scale */
        PRINT 'Check 13: NUMERIC or DECIMAL with scale of 0';
        BEGIN
			SET @checkSQL = 'USE [?]; INSERT INTO #results
									SELECT 13,
										   N''Data Formats'',
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

     END;
GO


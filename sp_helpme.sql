SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_helpme]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[sp_helpme] AS' 
END
GO

ALTER PROCEDURE [dbo].[sp_helpme]
	@objname SYSNAME = NULL		-- object name we're after
	,@epname SYSNAME = 'Description'
AS
																										
/*																										/*
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
*/ 
																										
BEGIN
	SET NOCOUNT ON;
	DECLARE	@dbname	SYSNAME
			,@objnameShort SYSNAME = N''
			,@no VARCHAR(5)
			,@yes VARCHAR(5)
			,@none VARCHAR(5)
			,@sysobj_type CHAR(2);

	DECLARE @objid INT
		   ,@hasParam INT = 0
		   ,@hasDepen BIT = 0
		   ,@hasSparse BIT = 0
		   ,@hasHidden BIT = 0
		   ,@hasMasked BIT = 0

	DECLARE @SQLString NVARCHAR(MAX) = N''
			,@msg NVARCHAR(MAX) = N''
			,@ParmDefinition NVARCHAR(500);

	SELECT @no = 'no', @yes = 'yes', @none = 'none';

	/* Check for Sparse Columns feature */
	IF 1 = (SELECT COUNT(*) FROM sys.all_columns AS ac WHERE ac.name = 'is_sparse' AND OBJECT_NAME(ac.object_id) = 'all_columns')
		BEGIN
			SET @hasSparse = 1;
		END;

	/* Check for Hidden Columns feature */
	IF 1 = (SELECT COUNT(*) FROM sys.all_columns AS ac WHERE ac.name = 'is_hidden' AND OBJECT_NAME(ac.object_id) = 'all_columns')
		BEGIN
			SET @hasHidden = 1;
		END;

	/* Check for Masked Columns feature */
	IF 1 = (SELECT COUNT(*) FROM sys.all_columns AS ac WHERE ac.name = 'is_masked' AND OBJECT_NAME(ac.object_id) = 'all_columns')
		BEGIN
			SET @hasMasked = 1;
		END;

	-- If no @objname given, give a little info about all objects.
	if @objname is null
	begin
		IF (SERVERPROPERTY('EngineEdition') != 5) -- SQL Server
		BEGIN
			SET @SQLString = N'SELECT
		            [Name]				= o.[name],
		            [Owner]				= USER_NAME(OBJECTPROPERTY([object_id], ''ownerid'')),
		            [Object_type]		= SUBSTRING(v.[name],5,31),
					[Create_datetime]	= o.create_date,
					[Modify_datetime]	= o.modify_date,
					[ExtendedProperty]	= ep.[value]
		        FROM sys.all_objects o
					INNER JOIN [master].dbo.spt_values v ON o.[type] = SUBSTRING(v.[name],1,2) COLLATE DATABASE_DEFAULT
					LEFT JOIN sys.extended_properties ep ON ep.major_id = o.[object_id]
									and ep.[name] = @epname
									AND ep.minor_id = 0
									AND ep.class = 1 
		        WHERE v.[type] = ''O9T''
		        ORDER BY [Owner] ASC, Object_type DESC, [name] ASC;';
			SET @ParmDefinition = N'@epname SYSNAME';

			EXEC sp_executesql @SQLString
				,@ParmDefinition
				,@epname;
		END
		ELSE -- Azure SQL
		BEGIN
			SET @SQLString = N'SELECT
		            [Name]          = o.[name],
		            [Owner]         = USER_NAME(OBJECTPROPERTY([object_id], ''ownerid'')),
		            [Object_type]   = SUBSTRING(v.[name],5,31),
					[Create_datetime]	= o.create_date,
					[Modify_datetime]	= o.modify_date,
					[ExtendedProperty]	= ep.[value]
		        FROM sys.all_objects o
					INNER JOIN sys.spt_values v ON o.[type] = SUBSTRING(v.[name],1,2) COLLATE DATABASE_DEFAULT
					LEFT JOIN sys.extended_properties ep ON ep.major_id = o.[object_id]
						and ep.[name] = @epname
						AND ep.minor_id = 0
						AND ep.class = 1 

		        WHERE v.[type] = ''O9T''
		        ORDER BY [Owner] ASC, Object_type DESC, [name] ASC;';
			SET @ParmDefinition = N'@epname SYSNAME';

			EXEC sp_executesql @SQLString
				,@ParmDefinition
				,@epname;
		END

		-- Display all user types
		SET @SQLString = N'SELECT
			[User_type]		= [name],
			[Storage_type]	= TYPE_NAME(system_type_id),
			[Length]		= max_length,
			[Prec]			= [precision],
			[Scale]			= [scale],
			[Nullable]		= CASE WHEN is_nullable = 1 THEN @yes ELSE @no END,
			[Default_name]	= ISNULL(OBJECT_NAME(default_object_id), @none),
			[Rule_name]		= ISNULL(OBJECT_NAME(rule_object_id), @none),
			[Collation]		= collation_name
		FROM sys.types
		WHERE user_type_id > 256
		ORDER BY [name];'
		SET @ParmDefinition = N'@yes VARCHAR(5), @no VARCHAR(5), @none VARCHAR(5)';

		EXEC sp_executesql @SQLString
			,@ParmDefinition
			,@yes
			,@no
			,@none;

		RETURN(0)
	END --All Sysobjects

	-- Make sure the @objname is local to the current database.
	SELECT @objnameShort = PARSENAME(@objname,1);
	SELECT @dbname = PARSENAME(@objname,3)
	IF @dbname IS NULL
		SELECT @dbname = DB_NAME()
	ELSE IF @dbname <> DB_NAME()
		BEGIN
			RAISERROR(15250,-1,-1);
			RETURN(1);
		END

	-- @objname must be either sysobjects or systypes: first look in sysobjects
	SET @SQLString = N'SELECT @objid			= object_id
							, @sysobj_type		= type 
						FROM sys.all_objects 
						WHERE object_id = OBJECT_ID(@objname);';  
	SET @ParmDefinition = N'@objname SYSNAME
						,@objid INT OUTPUT
						,@sysobj_type VARCHAR(5) OUTPUT';

	EXEC sp_executesql @SQLString
		,@ParmDefinition
		,@objName
		,@objid OUTPUT
		,@sysobj_type OUTPUT;

	-- If @objname not in sysobjects, try systypes
	IF @objid IS NULL
	BEGIN
		SET @SQLSTring = N'SELECT @objid = user_type_id
							FROM sys.types
							WHERE name = PARSENAME(@objname,1);'
		SET @ParmDefinition = N'@objname SYSNAME
							,@objid INT OUTPUT';
							
		EXEC sp_executesql @SQLString
			,@ParmDefinition
			,@objName
			,@objid OUTPUT;

		-- If not in systypes, return
		IF @objid IS NULL
		BEGIN
			RAISERROR(15009,-1,-1,@objname,@dbname)
			RETURN(1)
		END

		-- Data type help (prec/scale only valid for numerics)
		SET @SQLString = N'SELECT
								[Type_name]			= t.name,
								[Storage_type]		= type_name(system_type_id),
								[Length]			= max_length,
								[Prec]				= [precision],
								[Scale]				= [scale],
								[Nullable]			= case when is_nullable=1 then @yes else @no end,
								[Default_name]		= isnull(object_name(default_object_id), @none),
								[Rule_name]			= isnull(object_name(rule_object_id), @none),
								[Collation]			= collation_name,
								[ExtendedProperty]	= ep.[value]
							FROM sys.types t
								LEFT join sys.extended_properties ep ON ep.major_id = t.[user_type_id]
									AND ep.[name] = @epname
									AND ep.minor_id = 0
									AND ep.class = 6
							WHERE user_type_id = @objid';
		SET @ParmDefinition = N'@objid INT, @yes VARCHAR(5), @no VARCHAR(5), @none VARCHAR(5), @epname SYSNAME';

		EXECUTE sp_executesql @SQLString
			,@ParmDefinition
			,@objid
			,@yes
			,@no
			,@none
			,@epname;

		RETURN(0)
	END --Systypes

	-- FOUND IT IN SYSOBJECT, SO GIVE OBJECT INFO
	IF (SERVERPROPERTY('EngineEdition') != 5) -- SQL Server 
	BEGIN
		SET @SQLString = N'SELECT
			[Name]					= o.name,
			[Owner]					= user_name(ObjectProperty(object_id, ''ownerid'')),
	        [Type]					= substring(v.name,5,31),
			[Created_datetime]		= o.create_date,
			[Modify_datetime]		= o.modify_date,
			[ExtendedProperty]		= ep.[value]
		FROM sys.all_objects o
			INNER JOIN master.dbo.spt_values v ON o.type = substring(v.name,1,2) collate DATABASE_DEFAULT
			LEFT JOIN sys.extended_properties ep ON ep.major_id = o.[object_id]
				AND ep.[name] = @epname
				AND ep.minor_id = 0
				AND ep.class = 1 
		WHERE v.type = ''O9T''
			AND o.object_id = @objid;';

		SET @ParmDefinition = N'@objid INT, @epname SYSNAME';

		EXEC sp_executesql @SQLString
			,@ParmDefinition
			,@objid
			,@epname;

	END
	ELSE -- Azure SQL Database
	BEGIN
		SET @SQLString = N'SELECT
			[Name]				= o.name,
			[Owner]				= user_name(ObjectProperty( object_id, ''ownerid'')),
	        [Type]              = substring(v.name,5,31),
			[Created_datetime]	= o.create_date,
			[Modify_datetime]	= o.modify_date,
			[ExtendedProperty]		= ep.[value]
		FROM sys.all_objects o
			INNER JOIN sys.spt_values v ON o.type = substring(v.name,1,2) collate DATABASE_DEFAULT
			LEFT JOIN sys.extended_properties ep ON ep.major_id = o.[object_id]
				AND ep.[name] = @epname
		WHERE o.object_id = @objid
			AND v.type = ''O9T'';';

		SET @ParmDefinition = N'@objid INT, @epname SYSNAME';

		EXEC sp_executesql @SQLString
			,@ParmDefinition
			,@objid
			,@epname;
	END

	-- Display column metadata if table / view
	SET @SQLString = N'
	if exists (select * from sys.all_columns where object_id = @objid)
	begin

		-- SET UP NUMERIC TYPES: THESE WILL HAVE NON-BLANK PREC/SCALE
		-- There must be a '','' immediately after each type name (including last one),
		-- because that''s what we''ll search for in charindex later.
		declare @precscaletypes nvarchar(150)
		select @precscaletypes = N''tinyint,smallint,decimal,int,bigint,real,money,float,numeric,smallmoney,date,time,datetime2,datetimeoffset,''

		-- INFO FOR EACH COLUMN
		select
			[Column_name]			= ac.name,
			[Type]					= type_name(user_type_id),
			[Computed]				= case when ColumnProperty(object_id, ac.name, ''IsComputed'') = 0 then ''no'' else ''yes'' end,
			[Length]				= convert(int, max_length),
			-- for prec/scale, only show for those types that have valid precision/scale
			-- Search for type name + '','', because ''datetime'' is actually a substring of ''datetime2'' and ''datetimeoffset''
			[Prec]					= case when charindex(type_name(system_type_id) + '','', '''') > 0
										then convert(char(5),ColumnProperty(object_id, ac.name, ''precision''))
										else ''     '' end,
			[Scale]					= case when charindex(type_name(system_type_id) + '','', '''') > 0
										then convert(char(5),OdbcScale(system_type_id,scale))
										else ''     '' end,
			[Nullable]				= case when is_nullable = 0 then ''no'' else ''yes'' end, ';

			--Only include if the exist on the current version
			IF @hasMasked = 1
				BEGIN
					SET @SQLString = @SQLString +  N'[Masked]				= case when is_masked = 0 then ''no'' else ''yes'' end, '
				END
			IF @hasSparse = 1
				BEGIN
					SET @SQLString = @SQLString + N'[Sparse]				= case when is_sparse = 0 then ''no'' else ''yes'' end, '
				END
			IF @hasHidden = 1
				BEGIN
					SET @SQLString = @SQLString +  N'[Hidden]				= case when is_hidden = 0 then ''no'' else ''yes'' end, '
				END
			
			SET @SQLString = @SQLString + N'
			[Identity]				= case when is_identity = 0 then ''no'' else ''yes'' end,
			[TrimTrailingBlanks]	= case ColumnProperty(object_id, ac.name, ''UsesAnsiTrim'')
										when 1 then ''no''
										when 0 then ''yes''
										else ''(n/a)'' end,
			[FixedLenNullInSource]	= case
										when type_name(system_type_id) not in (''varbinary'',''varchar'',''binary'',''char'')
											then ''(n/a)''
										when is_nullable = 0 then ''no'' else ''yes'' end,
			[Collation]				= collation_name,
			[ExtendedProperty]		= ep.[value]
		from sys.all_columns ac
			LEFT JOIN sys.extended_properties ep ON ep.minor_id = ac.column_id
				AND ep.major_id = ac.[object_id]
				AND ep.[name] = @epname
				AND ep.class = 1
		where [object_id] = @objid
	END'
	SET @ParmDefinition = N'@objid INT, @epname SYSNAME';  
	EXEC sp_executesql @SQLString, @ParmDefinition, @objid = @objid, @epname = @epname;

	-- Identity & rowguid columns
	IF @sysobj_type in ('S ','U ','V ','TF')
	BEGIN
		DECLARE @colname SYSNAME = NULL;
		SET @SQLString = N'SELECT @colname = COL_NAME(@objid, column_id)
						FROM sys.identity_columns
						WHERE object_id = @objid;';
		SET @ParmDefinition = N'@objid INT, @colname SYSNAME OUTPUT';

		EXEC sp_executesql @SQLString
			,@ParmDefinition
			,@objid
			,@colname OUTPUT;

		--Identity
		IF (@colname IS NOT NULL)
			SELECT
				'Identity'				= @colname,
				'Seed'					= IDENT_SEED(@objname),
				'Increment'				= IDENT_INCR(@objname),
				'Not For Replication'	= COLUMNPROPERTY(@objid, @colname, 'IsIDNotForRepl')
		ELSE
			BEGIN
				SET @msg = 'No identity is defined on object %ls.';
				RAISERROR(@msg, 10, 1, @objname) WITH NOWAIT;
			END

		-- Rowguid
		SET @colname = NULL;
		SET @SQLString = N'SELECT @colname = [name]
						FROM sys.all_columns
						WHERE [object_id] = @objid AND is_rowguidcol = 1;';
		SET @ParmDefinition = N'@objid INT, @colname SYSNAME OUTPUT';

		EXEC sp_executesql @SQLString
			,@ParmDefinition
			,@objid
			,@colname OUTPUT;

		IF (@colname IS NOT NULL)
			SELECT 'RowGuidCol' = @colname;
		ELSE
			BEGIN
				SET @msg = 'No rowguid is defined on object %ls.';
				RAISERROR(@msg, 10, 1, @objname) WITH NOWAIT;
			END
	END

	-- Display any procedure parameters
	SET @SQLString = N'SELECT TOP (1) @hasParam = 1 FROM sys.all_parameters WHERE object_id = @objid';
	SET @ParmDefinition = N'@objid INT, @hasParam BIT OUTPUT';

	EXEC sp_executesql @SQLString
		,@ParmDefinition
		,@objid
		,@hasParam OUTPUT;

	--If parameters exist, show them
	IF @hasParam = 1
	BEGIN
		SET @SQLString = N'SELECT
			[Parameter_name]	= [name],
			[Type]				= TYPE_NAME(user_type_id),
			[Length]			= max_length,
			[Prec]				= CASE WHEN TYPE_NAME(system_type_id) = ''uniqueidentifier'' THEN [precision]
									ELSE OdbcPrec(system_type_id, max_length, [precision]) END,
			[Scale]				= ODBCSCALE(system_type_id, scale),
			[Param_order]		= parameter_id,
			[Collation]			= CONVERT([sysname], CASE WHEN system_type_id in (35, 99, 167, 175, 231, 239)
															THEN SERVERPROPERTY(''collation'') END)
		FROM sys.all_parameters
		WHERE [object_id] = @objid;';
		SET @ParmDefinition = N'@objid INT';

		EXEC sp_executesql  @SQLString
			,@ParmDefinition
			,@objid;
	END

	-- DISPLAY TABLE INDEXES & CONSTRAINTS

	IF @sysobj_type in ('S ','U ')
	BEGIN
		EXEC sys.sp_objectfilegroup @objid
		EXEC sys.sp_helpindex @objname
		EXEC sys.sp_helpconstraint @objname,'nomsg'

		SET @SQLString = N'SELECT @hasDepen = COUNT(*)
			FROM sys.objects obj, sysdepends deps
			WHERE obj.[type] =''V''
				AND obj.[object_id] = deps.id
				AND deps.depid = @objid
				AND deps.deptype = 1;';
		SET @ParmDefinition = N'@objid INT, @hasDepen INT OUTPUT';

		EXEC sp_executeSQL @SQLString
			,@ParmDefinition
			,@objid
			,@hasDepen OUTPUT;

		IF @hasDepen = 0
		BEGIN
			RAISERROR(15647,-1,-1,@objname) -- No views with schemabinding for reference table '%ls'.
		END
		ELSE
		BEGIN
			SET @SQLString = N'SELECT DISTINCT [Table is referenced by views] = OBJECT_SCHEMA_NAME(obj.object_id) + ''.'' + obj.[name] 
				FROM sys.objects obj
					INNER JOIN sysdepends deps ON obj.object_id = deps.id
				WHERE obj.[type] =''V''
					AND deps.depid = @objid
					AND deps.deptype = 1
				GROUP BY obj.[name], obj.object_id;';
			SET @ParmDefinition = N'@objid INT';

			EXEC sp_executesql @SQLString
				,@ParmDefinition
				,@objid;
		END
	END
	ELSE IF @sysobj_type in ('V ')
	BEGIN
		-- Views dont have constraints, but print these messages because 6.5 did
		RAISERROR(15469,-1,-1,@objname) -- No constraints defined for reference table '%ls'.
		RAISERROR(15470,-1,-1,@objname) -- No foreign keys for reference table '%ls'.
		EXEC sys.sp_helpindex @objname
	END

	RETURN (0) -- sp_helpme
END

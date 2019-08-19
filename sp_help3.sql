
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[sp_help3]
	@objname SYSNAME = NULL		-- object name we're after
	,@epname SYSNAME = 'MS_Description'
as
BEGIN
	-- PRELIMINARY
	SET NOCOUNT ON;
	DECLARE	@dbname	SYSNAME
			,@no VARCHAR(5)
			,@yes VARCHAR(5)
			,@none VARCHAR(5);
	DECLARE @SQLString nvarchar(MAX);

	SELECT @no = 'no', @yes = 'yes', @none = 'none';

	-- If no @objname given, give a little info about all objects.
	if @objname is null
	begin
		-- DISPLAY ALL SYSOBJECTS --
		if (serverproperty('EngineEdition') != 5)
		begin
		        select
		            'Name'          = o.name,
		            'Owner'         = user_name(ObjectProperty( object_id, 'ownerid')),
		            'Object_type'   = substring(v.name,5,31)
		        from sys.all_objects o, master.dbo.spt_values v
		        where o.type = substring(v.name,1,2) collate DATABASE_DEFAULT and v.type = 'O9T'
		        order by [Owner] asc, Object_type desc, Name asc
		end
		else 
		begin
			select
		            'Name'          = o.name,
		            'Owner'         = user_name(ObjectProperty( object_id, 'ownerid')),
		            'Object_type'   = substring(v.name,5,31)
		        from sys.all_objects o, sys.spt_values v
		        where o.type = substring(v.name,1,2) collate DATABASE_DEFAULT and v.type = 'O9T'
		        order by [Owner] asc, Object_type desc, Name asc
		end

		print ' '

		-- DISPLAY ALL USER TYPES
		select
			'User_type'	= name,
			'Storage_type'	= type_name(system_type_id),
			'Length'		= max_length,
			'Prec'		= [precision],
			'Scale'		= [scale],
			'Nullable'		= case when is_nullable = 1 then @yes else @no end,
			'Default_name'	= isnull(object_name(default_object_id), @none),
			'Rule_name'		= isnull(object_name(rule_object_id), @none),
			'Collation'		= collation_name
		from sys.types
		where user_type_id > 256
		order by name

		return(0)
	end --All Sysobjects

	-- Make sure the @objname is local to the current database.
	select @dbname = parsename(@objname,3)
	if @dbname is null
		select @dbname = db_name()
	else if @dbname <> db_name()
		begin
			RAISERROR(15250,-1,-1);
			RETURN(1);
		end

	-- @objname must be either sysobjects or systypes: first look in sysobjects
	  
	DECLARE @ParmDefinition nvarchar(500);  
	DECLARE @objid INT
			, @sysobj_type CHAR(2);
	SET @SQLString = N'	select @objidOUT = object_id
						, @sysobj_typeOUT = type 
						from sys.all_objects 
						where object_id = object_id(@objname);';  
	SET @ParmDefinition = N'@objname SYSNAME
						,@objidOUT INT OUTPUT
						,@sysobj_typeOUT VARCHAR(5) OUTPUT';    
	EXECUTE sp_executesql @SQLString
		,@ParmDefinition
		,@objName = @objName
		,@objidOUT= @objid OUTPUT
		,@sysobj_typeOUT = @sysobj_type OUTPUT;

	-- IF NOT IN SYSOBJECTS, TRY SYSTYPES --
	if @objid is null
	begin
		-- UNDONE: SHOULD CHECK FOR AND DISALLOW MULTI-PART NAME
		SET @SQLString = N'select @objid = type_id(@objname);';  
		SET @ParmDefinition = N'@objname SYSNAME
							,@objidOUT INT OUTPUT';    
		EXECUTE sp_executesql @SQLString
			,@ParmDefinition
			,@objName = @objName
			,@objidOUT= @objid OUTPUT;

		-- IF NOT IN SYSTYPES, GIVE UP
		if @objid is null
		begin
			raiserror(15009,-1,-1,@objname,@dbname)
			return(1)
		end

		--TODO: Switch to dynamic sql
		-- DATA TYPE HELP (prec/scale only valid for numerics)
		select
			'Type_name'	= name,
			'Storage_type'	= type_name(system_type_id),
			'Length'		= max_length,
			'Prec'			= [precision],
			'Scale'			= [scale],
			'Nullable'			= case when is_nullable=1 then @yes else @no end,
			'Default_name'	= isnull(object_name(default_object_id), @none),
			'Rule_name'		= isnull(object_name(rule_object_id), @none),
			'Collation'		= collation_name
		from sys.types
		where user_type_id = @objid

		return(0)
	end --Systypes

	-- FOUND IT IN SYSOBJECT, SO GIVE OBJECT INFO
	if (serverproperty('EngineEdition') != 5) --Anything but "SQL Database"
	begin
		select
			'Name'				= o.name,
			'Owner'				= user_name(ObjectProperty( object_id, 'ownerid')),
	        'Type'              = substring(v.name,5,31),
			'Created_datetime'	= o.create_date
		from sys.all_objects o, master.dbo.spt_values v
		where o.object_id = @objid and o.type = substring(v.name,1,2) collate DATABASE_DEFAULT and v.type = 'O9T'
	end
	else --SQL Database
	begin
		select
			'Name'				= o.name,
			'Owner'				= user_name(ObjectProperty( object_id, 'ownerid')),
	        'Type'              = substring(v.name,5,31),
			'Created_datetime'	= o.create_date
		from sys.all_objects o, sys.spt_values v
		where o.object_id = @objid and o.type = substring(v.name,1,2) collate DATABASE_DEFAULT and v.type = 'O9T'
	end

	-- DISPLAY COLUMN IF TABLE / VIEW
	
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
			''Column_name''			= ac.name,
			''Type''					= type_name(user_type_id),
			''Computed''				= case when ColumnProperty(object_id, ac.name, ''IsComputed'') = 0 then ''no'' else ''yes'' end,
			''Length''					= convert(int, max_length),
			-- for prec/scale, only show for those types that have valid precision/scale
			-- Search for type name + '','', because ''datetime'' is actually a substring of ''datetime2'' and ''datetimeoffset''
			''Prec''					= case when charindex(type_name(system_type_id) + '','', '''') > 0
										then convert(char(5),ColumnProperty(object_id, ac.name, ''precision''))
										else ''     '' end,
			''Scale''					= case when charindex(type_name(system_type_id) + '','', '''') > 0
										then convert(char(5),OdbcScale(system_type_id,scale))
										else ''     '' end,
			''Nullable''				= case when is_nullable = 0 then ''no'' else ''yes'' end,
			''Hidden''		= case when is_hidden = 0 then ''no'' else ''yes'' end,
			''Masked''		= case when is_masked = 0 then ''no'' else ''yes'' end,
			''Sparse''		= case when is_sparse = 0 then ''no'' else ''yes'' end,
			''Identity''		= case when is_identity = 0 then ''no'' else ''yes'' end,
			''TrimTrailingBlanks''	= case ColumnProperty(object_id, ac.name, ''UsesAnsiTrim'')
										when 1 then ''no''
										when 0 then ''yes''
										else ''(n/a)'' end,
			''FixedLenNullInSource''	= case
						when type_name(system_type_id) not in (''varbinary'',''varchar'',''binary'',''char'')
							then ''(n/a)''
						when is_nullable = 0 then ''no'' else ''yes'' end,
			''Collation''		= collation_name,
			''ExtendedProperty''	= ep.[value]
		from sys.all_columns ac
			left join sys.extended_properties ep ON ep.minor_id = ac.column_id
				and ep.major_id = ac.[object_id]
				and ep.[name] = @epname
		where object_id = @objid
	END'
	SET @ParmDefinition = N'@objid INT, @epname SYSNAME';  
	EXEC sp_executesql @SQLString, @ParmDefinition, @objid = @objid, @epname =@epname;
	RETURN;

		-- IDENTITY COLUMN?
		if @sysobj_type in ('S ','U ','V ','TF')
		begin
			print ' '
			declare @colname sysname
			select @colname = col_name(@objid, column_id) from sys.identity_columns where object_id = @objid
			select
				'Identity'				= isnull(@colname,'No identity column defined.'),
				'Seed'				= ident_seed(@objname),
				'Increment'			= ident_incr(@objname),
				'Not For Replication'	= ColumnProperty(@objid, @colname, 'IsIDNotForRepl')
			-- ROWGUIDCOL?
			print ' '
			select @colname = null
			select @colname = name from sys.columns where object_id = @objid and is_rowguidcol = 1
			select 'RowGuidCol' = isnull(@colname,'No rowguidcol column defined.')
		end
	--end

	-- DISPLAY ANY PARAMS
	if exists (select * from sys.all_parameters where object_id = @objid)
	begin
		-- INFO ON PROC PARAMS
		print ' '
		select
			'Parameter_name'	= name,
			'Type'			= type_name(user_type_id),
			'Length'			= max_length,
			'Prec'			= case when type_name(system_type_id) = 'uniqueidentifier' then precision
								else OdbcPrec(system_type_id, max_length, precision) end,
			'Scale'			= OdbcScale(system_type_id, scale),
			'Param_order'		= parameter_id,
			'Collation'			= convert(sysname, case when system_type_id in (35, 99, 167, 175, 231, 239)
						then ServerProperty('collation') end)

		from sys.all_parameters where object_id = @objid
	end

	-- DISPLAY TABLE INDEXES & CONSTRAINTS
	if @sysobj_type in ('S ','U ')
	begin
		print ' '
		EXEC sys.sp_objectfilegroup @objid
		print ' '
		EXEC sys.sp_helpindex @objname
		print ' '
		EXEC sys.sp_helpconstraint @objname,'nomsg'
		if (select count(*) from sys.objects obj, sysdepends deps
			where obj.type ='V' and obj.object_id = deps.id and deps.depid = @objid and deps.deptype = 1) = 0
		begin
			raiserror(15647,-1,-1,@objname) -- No views with schemabinding reference table '%ls'.
		end
		else
		begin
			select distinct 'Table is referenced by views' = obj.name from sys.objects obj, sysdepends deps
				where obj.type ='V' and obj.object_id = deps.id and deps.depid = @objid
					and deps.deptype = 1 group by obj.name
		end
	end
	else if @sysobj_type in ('V ')
	begin
		-- VIEWS DONT HAVE CONSTRAINTS, BUT PRINT THESE MESSAGES BECAUSE 6.5 DID
		print ' '
		raiserror(15469,-1,-1,@objname) -- No constraints defined
		print ' '
		raiserror(15470,-1,-1,@objname) -- No foreign keys reference table '%ls'.
		EXEC sys.sp_helpindex @objname
	end

	return (0) -- sp_help
END
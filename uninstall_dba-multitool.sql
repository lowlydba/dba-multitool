/* Drop sp_doc */
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_doc]') AND [type] IN (N'P', N'PC'))
    BEGIN;
        DROP PROCEDURE [dbo].[sp_doc];
    END
GO

/* Drop sp_sizeoptimiser */
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_sizeoptimiser]'))
	BEGIN;
		DROP PROCEDURE [dbo].[sp_sizeoptimiser];
	END

IF EXISTS (SELECT * FROM sys.types st JOIN sys.schemas ss ON st.schema_id = ss.schema_id WHERE st.name = N'SizeOptimiserTableType' AND ss.name = N'dbo')
	BEGIN;
		DROP TYPE [dbo].[SizeOptimiserTableType];
	END
GO

/* Drop sp_estindex */
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_estindex]') AND [type] IN (N'P', N'PC'))
	BEGIN;
		DROP PROCEDURE [dbo].[sp_estindex];
	END
GO

/* Drop sp_helpme */
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_helpme]') AND [type] IN (N'P', N'PC'))
	BEGIN;
		DROP PROCEDURE [dbo].[sp_helpme];
	END
GO


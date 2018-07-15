DECLARE @databases AS dbo.sizeoptimisertabletype;

INSERT INTO @databases 
SELECT 'master';

EXEC sp_sizeoptimiser @Databases = @databases ;
GO
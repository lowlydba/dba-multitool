#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.1.0" }
param()

BeforeDiscovery {
    #. "$PSScriptRoot\constants.ps1"
}

Describe "sp_sizeoptimiser" {
    Context "tSQLt Tests" {
        BeforeAll {
            $storedProc = "sp_sizeoptimiser"
            $testPath = "tests\"
            $testInstallScript = "$storedProc.Tests.sql"
            $runTestQuery = "EXEC tSQLt.Run '[$storedProc]'"
            $queryTimeout = 300

            $Hash = @{
                ConnectionString = "Data Source=$env:SQLINSTANCE;Initial Catalog=$env:DATABASE;Integrated Security=True;TrustServerCertificate=true"
                Verbose = $true
            }

            # Install tests
            ForEach ($File in Get-ChildItem -Path $testPath -Filter $testInstallScript) {
                Invoke-Sqlcmd @Hash -InputFile $File.FullName
            }
        }
        It "All tests" {
            { Invoke-Sqlcmd @Hash -Query $runTestQuery -QueryTimeout $queryTimeout } | Should -Not -Throw -Because "tSQLt unit tests must pass"
        }
        It "Finds oversized integer columns from statistics" {
            $tableName = "dbo.SizeOptimiserIntegerColumns"
            $setupQuery = @"
IF OBJECT_ID(N'$tableName', N'U') IS NOT NULL
    DROP TABLE $tableName;
IF TYPE_ID(N'dbo.SizeOptimiserIntegerAlias') IS NOT NULL
    DROP TYPE dbo.SizeOptimiserIntegerAlias;

CREATE TYPE dbo.SizeOptimiserIntegerAlias
FROM BIGINT;
GO

CREATE TABLE $tableName
    ([Id] BIGINT PRIMARY KEY
    ,[TinyIntCandidate] BIGINT NOT NULL
    ,[SmallIntCandidate] INT NOT NULL
    ,[NegativeCandidate] BIGINT NOT NULL
    ,[IdentityCandidate] INT IDENTITY(1, 1) NOT NULL
    ,[AliasCandidate] dbo.SizeOptimiserIntegerAlias NULL
    ,[OutOfRangeCandidate] INT NOT NULL);

INSERT INTO $tableName
    ([Id], [TinyIntCandidate], [SmallIntCandidate], [NegativeCandidate], [AliasCandidate], [OutOfRangeCandidate])
VALUES
    (1, 0, -32768, -1, 10, 0),
    (2, 100, 0, 100, 20, 32768),
    (3, 255, 32767, 200, 30, 50000);

CREATE STATISTICS [stat_TinyIntCandidate]
ON $tableName ([TinyIntCandidate])
WITH FULLSCAN;
CREATE STATISTICS [stat_SmallIntCandidate]
ON $tableName ([SmallIntCandidate])
WITH FULLSCAN;
CREATE STATISTICS [stat_NegativeCandidate]
ON $tableName ([NegativeCandidate])
WITH FULLSCAN;
CREATE STATISTICS [stat_IdentityCandidate]
ON $tableName ([IdentityCandidate])
WITH FULLSCAN;
CREATE STATISTICS [stat_AliasCandidate]
ON $tableName ([AliasCandidate])
WITH FULLSCAN;
CREATE STATISTICS [stat_OutOfRangeCandidate]
ON $tableName ([OutOfRangeCandidate])
WITH FULLSCAN;
"@
            $runQuery = @"
DECLARE @IncludeDatabases [dbo].[SizeOptimiserTableType];
INSERT INTO @IncludeDatabases
VALUES (DB_NAME());

EXEC [dbo].[sp_sizeoptimiser]
    @IncludeDatabases = @IncludeDatabases
    ,@Verbose = 0;
"@

            try {
                Invoke-Sqlcmd @Hash -Query $setupQuery
                $results = Invoke-Sqlcmd @Hash -Query $runQuery -QueryTimeout $queryTimeout
                $recommendations = @($results | Where-Object {
                    $_.ref_link -like "*oversized-integer-data-types"
                })

                $recommendations | Should -HaveCount 3
                @($recommendations | Where-Object {
                    $_.col_name -eq "[TinyIntCandidate]" -and $_.message -like "*TINYINT.*"
                }) | Should -HaveCount 1
                @($recommendations | Where-Object {
                    $_.col_name -in @("[SmallIntCandidate]", "[NegativeCandidate]") -and
                    $_.message -like "*SMALLINT.*"
                }) | Should -HaveCount 2
                @($recommendations | Where-Object {
                    $_.col_name -in @(
                        "[Id]", "[IdentityCandidate]", "[AliasCandidate]", "[OutOfRangeCandidate]"
                    )
                }) | Should -HaveCount 0
            }
            finally {
                $cleanupQuery = @"
IF OBJECT_ID(N'$tableName', N'U') IS NOT NULL
    DROP TABLE $tableName;
IF TYPE_ID(N'dbo.SizeOptimiserIntegerAlias') IS NOT NULL
    DROP TYPE dbo.SizeOptimiserIntegerAlias;
"@
                Invoke-Sqlcmd @Hash -Query $cleanupQuery
            }
        }
    }
}

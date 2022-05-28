#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.1.0" }

$storedProcedures = @('sp_doc', 'sp_estindex', 'sp_helpme', 'sp_sizeoptimiser')

foreach ($storedProc in $storedProcedures) {
    Describe "$storedProc" {
        Context "tSQLt Tests" {
            BeforeAll {
                $testPath = "tests\"
                $testInstallScript = "$storedProc.Tests.sql"
                $runTestQuery = "EXEC tSQLt.Run '[$storedProc]'"
                $queryTimeout = 300

                $Hash = @{
                    SqlInstance = $env:SQLINSTANCE
                    Database = $env:DATABASE
                    Verbose = $true
                    EnableException = $true
                }

                # Install tests
                ForEach ($File in Get-ChildItem -Path $testPath -Filter $testInstallScript) {
                    Invoke-DbaQuery @Hash -File $File.FullName
                }
            }
            It "All tests" {
                { Invoke-DbaQuery @Hash -Query $runTestQuery -QueryTimeout $queryTimeout } | Should -Not -Throw -Because "tSQLt unit tests must pass"
            }
        }
    }
}

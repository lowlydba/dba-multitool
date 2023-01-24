#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.1.0" }
param()

BeforeDiscovery {
    #. "$PSScriptRoot\constants.ps1"
}

Describe "sp_doc" {
    Context "tSQLt Tests" {
        BeforeAll {
            $storedProc = "sp_doc"
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
    }
}

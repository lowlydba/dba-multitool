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
                ServerInstance = $env:SQLINSTANCE
                Database = $env:DATABASE
                Verbose = $true
            }

            # Install tests
            ForEach ($File in Get-ChildItem -Path $testPath -Filter $testInstallScript) {
                Invoke-SqlCmd @Hash -InputFile $File.FullName
            }
        }
        It "All tests" {
            { Invoke-SqlCmd @Hash -Query $runTestQuery -QueryTimeout $queryTimeout } | Should -Not -Throw -Because "tSQLt unit tests must pass"
        }
    }
}

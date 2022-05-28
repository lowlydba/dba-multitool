#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.1.0" }
param()

BeforeDiscovery {
    #. "$PSScriptRoot\constants.ps1"
    #$InstallerFile = "install_dba-multitool.sql"
    #Get-ChildItem -Path ".\" -Filter "sp_*.sql" | Get-Content | Out-File $InstallerFile -Encoding ascii
}

Describe "sp_estindex" {
    Context "tSQLt Tests" {
        BeforeAll {
            $installMultiToolQuery = ".\install_dba-multitool.sql"
            $storedProc = "sp_estindex"
            $testPath = "tests\"
            $testInstallScript = "$storedProc.Tests.sql"
            $runTestQuery = "EXEC tSQLt.Run '[$storedProc]'"
            $queryTimeout = 300

            # Create connection
            $Hash = @{
                SqlInstance = $env:SQLINSTANCE
                Database = $env:DATABASE
                Verbose = $true
                EnableException = $true
            }

            # Install DBA MultiTool
            Invoke-DbaQuery @Hash -File $installMultiToolQuery

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

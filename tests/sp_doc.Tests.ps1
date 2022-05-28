#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.1.0" }
param()

BeforeDiscovery {
    #. "$PSScriptRoot\constants.ps1"
    #$InstallerFile = "install_dba-multitool.sql"
    #Get-ChildItem -Path ".\" -Filter "sp_*.sql" | Get-Content | Out-File $InstallerFile -Encoding ascii
}

Describe "sp_doc" {
    Context "tSQLt Tests" {
        BeforeAll {
            $InstallMultiToolQuery = ".\install_dba-multitool.sql"
            $StoredProc = "sp_doc"
            $TestPath = "tests\"
            $RunTestQuery = "EXEC tSQLt.Run '[$StoredProc]'"
            $QueryTimeout = 300

            # Create connection
            $Hash = @{
                SqlInstance = $env:SQLINSTANCE
                Database = $env:DATABASE
                Verbose = $true
                EnableException = $true
            }

            # Install DBA MultiTool
            Invoke-DbaQuery @Hash -File $InstallMultiToolQuery

            # Install tests
            ForEach ($File in Get-ChildItem -Path $TestPath -Filter "$StoredProc.Tests.sql") {
                Invoke-DbaQuery @Hash -File $File.FullName
            }
        }
        It "All tests" {
            { Invoke-DbaQuery @Hash -Query $RunTestQuery -QueryTimeout $QueryTimeout } | Should -Not -Throw -Because "tSQLt unit tests must pass"
        }
    }
}

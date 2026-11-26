#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.1.0" }
param()

Describe "sp_help_revlogin" {
    Context "tSQLt Tests" {
        BeforeAll {
            $testClass = "sp_help_revlogin"
            $testPath = "tests\"
            $testInstallScript = "$testClass.Tests.sql"
            $runTestQuery = "EXEC tSQLt.Run '[$testClass]'"
            $queryTimeout = 300

            $Hash = @{
                ConnectionString = "Data Source=$env:SQLINSTANCE;Initial Catalog=$env:DATABASE;Integrated Security=True;TrustServerCertificate=true"
                Verbose = $true
            }

            ForEach ($File in Get-ChildItem -Path $testPath -Filter $testInstallScript) {
                Invoke-Sqlcmd @Hash -InputFile $File.FullName
            }
        }
        It "All tests" {
            { Invoke-Sqlcmd @Hash -Query $runTestQuery -QueryTimeout $queryTimeout } |
                Should -Not -Throw -Because "tSQLt unit tests must pass"
        }
    }
}

#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.0.0" }

BeforeAll {
    . "$PSScriptRoot\constants.ps1"
}

Describe "sp_doc" {
    Context "tSQLt Tests" {
        BeforeAll {
            $TestClass = "sp_doc"
            $RunTestQuery = "EXEC tSQLt.Run '$TestClass'"

            # Create connection
            $Hash = @{
                SqlInstance     = $SqlInstance
                Database        = $Database
                Verbose         = $true
                EnableException = $true
            }

            If ($script:IsAzureSQL) {
                $SecPass = ConvertTo-SecureString -String $Pass -AsPlainText -Force
                $Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $SecPass
                $Hash.add("SqlCredential", $Credential)
            }

            # Install tests
            ForEach ($filename in Get-ChildItem -Filter "*.Tests.sql") {
                Invoke-DbaQuery @Hash -File $filename.FullName
            }

            # Generate all-in-one installer script
            Get-ChildItem -Path ".\" -Filter "sp_*.sql" | Get-Content | Out-File $InstallerFile -Encoding utf8

            # Install DBA MultiTool
            Invoke-DbaQuery @Hash -File $InstallMultiToolQuery
        }
        It "All tests" {
            { Invoke-DbaQuery @Hash -Query $RunTestQuery } | Should -Not -Throw -Because "tSQLt unit tests must pass"
        }
    }
    Context "TSQLLint" {
        BeforeAll {
            $Script = "sp_doc.sql"

            # TSQLLint results format: https://gist.github.com/LowlyDBA/caf744ce1a1498fee18e41d69d15f56d
            $LintResult = tsqllint -c $TSQLLintConfig $Script
            $LintErrors = $LintResult | Select-Object -Last 2 | Select-Object -First 1
            $LintWarnings = $LintResult | Select-Object -Last 2 | Select-Object -Last 1
        }
        It "Errors" {
            $LintErrors[0] | Should -Be "0" -Because "Lint errors are a no-no"
        }
        It "Warnings" {
            $LintWarnings[0] | Should -Be "0" -Because "Lint warnings are a no-no"
        }
    }
}


Describe 'sp_estindex' {
    Context 'tSQLt Tests' {    
        BeforeAll {
            . "$PSScriptRoot\constants.ps1"
            $TestClass = "sp_estindex"
            $Query = "EXEC tsqlt.Run '$TestClass'"
            
            $Hash = @{
                SqlInstance     = $SqlInstance
                Database        = $Database
                Query           = $Query
                Verbose         = $true
                EnableException = $true
            }  
        }
        It 'All tests' {

            If ($script:IsAzureSQL) {
                
                $SecPass = ConvertTo-SecureString -String $Pass -AsPlainText -Force
                $Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $SecPass
                $Hash.add("SqlCredential", $Credential)

                { Invoke-DbaQuery @Hash } | Should -Not -Throw -Because "tsqlt unit tests must pass"
            }

            Else {
                { Invoke-DbaQuery @Hash } | Should -Not -Throw -Because "tsqlt unit tests must pass"
            }
        }     
    }
    Context 'TSQLLint' {    
        BeforeAll {
            . "$PSScriptRoot\constants.ps1"
            $Script = "sp_estindex.sql"
            $TSQLLintConfig = ".\appveyor\tsqllint\.tsqllintrc_150"

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
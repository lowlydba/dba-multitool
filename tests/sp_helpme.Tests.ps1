. "$PSScriptRoot\constants.ps1"

Describe 'sp_helpme' {
    Context 'tSQLt Tests' {    
        BeforeAll {
            $TestClass = "sp_helpme"
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
            $Script = "sp_helpme"
            
            # TSQLLint results format: https://gist.github.com/LowlyDBA/caf744ce1a1498fee18e41d69d15f56d
            $LintResult = tsqllint "$Script.sql" --config $TSQLLintConfig 
            $LintSummary = $LintResult | Select-Object -Last 2
            $LintErrors = $LintSummary | Select-Object -First 1
            $LintWarnings = $LintSummary | Select-Object -Last 1
        }
        It 'Errors' {
            Try {
                $LintErrors[0] | Should -Be '0' -Because "Lint errors are a no-no"
            }

            Catch {
                Write-Host $LintResult
                Throw
            }
        }
        It 'Warnings' {
            $LintWarnings[0] | Should -Be '0' -Because "Lint warnings are a no-no"
        }
    }
}
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

                { Invoke-DbaQuery @Hash } | Should -Not -Throw
            }

            Else {
                { Invoke-DbaQuery @Hash } | Should -Not -Throw
            }
        }     
    }
}
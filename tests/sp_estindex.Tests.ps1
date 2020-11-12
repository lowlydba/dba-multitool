. "$PSScriptRoot\constants.ps1"

Describe 'sp_estindex' {
    Context 'tSQLt Tests' {    
        BeforeAll {
            $SqlInstance = $env:DB_INSTANCE
            $Database = $env:TARGET_DB
            $TestClass = "sp_estindex"
            $Query = "EXEC tsqlt.Run '$TestClass'"
            $Pass = $env:AZURE_SQL_PASS
            $User = $env:AZURE_SQL_USER
            
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
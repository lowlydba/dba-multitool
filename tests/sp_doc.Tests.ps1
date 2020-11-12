. "$PSScriptRoot\constants.ps1"

Describe 'sp_doc' {
    Context 'tSQLt Tests' {    
        BeforeAll {
            $SqlInstance = "localhost"
            $Database = "tsqlt"
            $TestClass = "sp_doc"
            $Query = "EXEC tsqlt.Run '$TestClass'"
            
            $hash = @{            
                SqlInstance     = $SqlInstance
                Database        = $Database
                Query           = $Query
                Verbose         = $true
                EnableException = $true
            }  
        }
        It 'All tests' {

            If ($script:IsAzureSQL) {
                
                # $PWord = ConvertTo-SecureString -String $env:AZURE_SQL_PASS -AsPlainText -Force
                # $Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $env:AZURE_SQL_USER, $PWord
                # $hash.add("SqlCredential", $Credential)

                { Invoke-SqlCmd -ServerInstance $SqlInstance -Database $Database -Query $Query -Verbose -Username $env:AZURE_SQL_USER -Password $env:AZURE_SQL_PASS | Out-Null } | Should -Not -Throw
            }

            Else {
                { Invoke-DbaQuery @hash } | Should -Not -Throw
            }
        }     
    }
}
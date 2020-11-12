$IsAzureSQL = [System.Convert]::ToBoolean($env:AzureSQL)

Describe 'sp_helpme' {
    Context 'tSQLt Tests' {    
        BeforeAll {
            $SqlInstance = "localhost"
            $Database = "tsqlt"
            $TestClass = "sp_helpme"
            $Query = "EXEC [tsqlt].[Run] '$TestClass'"

            $hash = @{            
                SqlInstance = $SqlInstance
                Database   = $Database
                Query  =  $Query
                Verbose = $true
                EnableException = $true
            }  
        }
        It 'All tests' {

            If ($IsAzureSQL) {
                $PWord = ConvertTo-SecureString -String $env:AZURE_SQL_PASS -AsPlainText -Force
                $Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $env:AZURE_SQL_USER, $PWord
                $hash.add("SqlCredential", $Credential)

                { Invoke-DbaQuery @hash } | Should -Not -Throw
            }

            Else {
                { Invoke-DbaQuery @hash } | Should -Not -Throw
            }  
        }
    }
}
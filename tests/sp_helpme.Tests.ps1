Describe 'sp_helpme' {
    Context 'tSQLt Tests' {    
        BeforeAll {
            $SqlInstance = "localhost"
            $Database = "tsqlt"
            $TestClass = "sp_helpme"
            $Query = "EXEC [tsqlt].[Run] '$TestClass'"
        }
        It 'All tests' {
            { Invoke-SqlCmd2 -ServerInstance $SqlInstance -Database $Database -Query $Query -Verbose -Debug:$false } | Should -Not -Throw
        }     
    }
}
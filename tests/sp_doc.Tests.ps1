Describe 'sp_doc' {
    Context 'tSQLt Tests' {    
        BeforeAll {
            $SqlInstance = "localhost"
            $Database = "tsqlt"
            $TestClass = "sp_doc"
            $Query = "EXEC tsqlt.Run '$TestClass'"
        }
        It 'All tests' {
            { Invoke-DbaQuery -SqlInstance $SqlInstance -Database $Database -Query $Query -Verbose } | Should -Not -Throw
        }     
    }
}
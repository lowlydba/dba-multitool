Describe 'sp_doc' {
    Context 'tSQLt Tests' {    
        BeforeAll {
            $SqlInstance = "localhost"
            $Database = "tsqlt"
            $TestClass = "sp_doc"
            $Query = "EXEC tsqlt.Run '$TestClass'"
        }
        It 'All tests' {
            { Invoke-DbaQuery -Query $Query -Database $Database -SqlInstance $SqlInstance -EnableException -Verbose -WarningAction SilentlyContinue } | Should -Not -Throw
        }     
    }
}
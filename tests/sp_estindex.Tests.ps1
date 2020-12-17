#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.0.0" }

#PSScriptAnalyzer rule excludes
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
param()

BeforeAll {
    . "$PSScriptRoot\constants.ps1"
    Get-ChildItem -Path ".\" -Filter "sp_*.sql" | Get-Content | Out-File $InstallerFile -Encoding utf8
}

Describe "sp_estindex" {
    Context "tSQLt Tests" {
        BeforeAll {
            $StoredProc = "sp_estindex"
            $TestPath = "tests\"
            $RunTestQuery = "EXEC tSQLt.Run '$StoredProc'"

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

            # Install DBA MultiTool
            Invoke-DbaQuery @Hash -File $InstallMultiToolQuery

            # Install tests
            ForEach ($File in Get-ChildItem -Path $TestPath -Filter "$StoredProc.Tests.sql") {
                Invoke-DbaQuery @Hash -File $File.FullName
            }
        }
        It "All tests" {
            { Invoke-DbaQuery @Hash -Query $RunTestQuery } | Should -Not -Throw -Because "tSQLt unit tests must pass"
        }
    }
}
using namespace System.IO.Path

#PSScriptAnalyzer rule excludes
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '')]
param(
    [Parameter()]
    [switch]$LocalTest,
    [string]$CoverageXMLPath = $env:COV_REPORT,
    [string]$SqlInstance = $env:DB_INSTANCE,
    [string]$Database = $env:DATABASE,
    [bool]$IsAzureSQL = [System.Convert]::ToBoolean($env:AzureSQL),
    [string]$User = $env:AZURE_SQL_USER,
    [string]$Pass = $env:AZURE_SQL_PASS,
    [System.ConsoleColor]$Color = "Green",
    [switch]$CodeCoverage
)

$ErrorActionPreference = "Stop"
$TestFiles = Get-ChildItem -Path .\tests\*.Tests.ps1
$FailedTests = 0

# Install multitool
Get-ChildItem -Path ".\" -Filter "sp_*.sql" | Get-Content | Out-File $Env:INSTALLER_FILE -Encoding ascii
Invoke-DbaQuery -SqlInstance $SqlInstance -Database $Database -File $Env:INSTALLER_FILE

# Run Tests
ForEach ($file in $TestFiles) {
    Add-AppveyorTest -Name $file.BaseName -Framework NUnit -Filename $file.FullName -Outcome Running

    $PesterResult = Invoke-Pester -Path $file.FullName -Output Detailed -PassThru
    $Outcome = "Passed"
    If ($PesterResult.FailedCount -gt 0) {
        $Outcome = "Failed"
        $FailedTests ++
    }

    Update-AppveyorTest -Name $file.BaseName -Framework NUnit -FileName $file.FullName -Outcome $Outcome -Duration $PesterResult.UserDuration.Milliseconds
}

# Check for failures
If ($FailedTests -gt 0) {
    Throw "$FailedTests tests failed."
}

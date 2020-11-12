param( 
    [Parameter()] 
    [string]$FilePath = "tests\run",
    [string]$SqlInstance = $env:DB_INSTANCE,
    [string]$Database = $env:TARGET_DB,
    [bool]$IsAzureSQL = [System.Convert]::ToBoolean($env:AzureSQL),
    [string]$User = $env:AZURE_SQL_USER,
    [string]$Pass = $env:AZURE_SQL_PASS,
    [string]$Color = "Green"
)

$ErrorActionPreference = "Stop"

$TestFiles = Get-ChildItem -Path .\tests\*.Tests.ps1

ForEach ($file in $TestFiles) {
    Add-AppveyorTest -Name $file.Name -Framework NUnit -Filename $file.FullName -Outcome Running
    $PesterResult = Invoke-Pester -Path $file.FullName -Output Detailed -PassThru
    $Outcome = "Passed"
    If ($PesterResult.FailedCount -gt 0) {
        $Outcome = "Failed"
    }
    Update-AppveyorTest -Name $file.Name -Framework NUnit -FileName $file.FullName -Outcome $Outcome -Duration $PesterResult.UserDuration.Milliseconds
}
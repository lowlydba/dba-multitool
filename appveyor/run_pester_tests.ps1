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
    [string]$Database = $env:TARGET_DB,
    [bool]$IsAzureSQL = [System.Convert]::ToBoolean($env:AzureSQL),
    [string]$User = $env:AZURE_SQL_USER,
    [string]$Pass = $env:AZURE_SQL_PASS,
    [string]$Color = "Green",
    [switch]$CodeCoverage
)
. ".\tests\constants.ps1"
$ErrorActionPreference = "Stop"
$TestFiles = Get-ChildItem -Path .\tests\*.Tests.ps1
$FailedTests = 0

function Start-CodeCoverage {
param(
    [string]$SqlInstance,
    [string]$Database,
    [string]$User,
    [string]$Pass,
    [bool]$IsAzureSQL,
    [string]$Color
)
    # Setup vars
    If ($IsAzureSQL) {
        $ConnString = "server=$SqlInstance;initial catalog=$Database;User Id=$User;pwd=$Pass"
    }

    Else {
        $ConnString = "server=$SqlInstance;initial catalog=$Database;Trusted_Connection=yes"
    }

    $NugetPath = (Get-Package GOEddie.SQLCover).Source | Convert-Path
    $SQLCoverRoot = Split-Path $NugetPath
    $SQLCoverPath = Join-Path $SQLCoverRoot "lib"
    $SQLCoverDllFullPath = Join-Path $SQLCoverPath "SQLCover.dll"

    # Add DLL
    Add-Type -Path $SQLCoverDllFullPath

    # Start covering
    Write-Host "Starting SQLCover..." -ForegroundColor $Color
    $global:SQLCover = New-Object SQLCover.CodeCoverage($ConnString, $Database)
    $SQLCover.Start() | Out-Null
}

function Complete-CodeCoverage {
param (
    [string]$CoverageXMLPath,
    [string]$Color
)
    # Stop covering
    Write-Host "Stopping SQLCover..." -ForegroundColor $Color
    $coverageResults = $global:SQLCover.Stop()

    # Export results
    Write-Host "Generating code coverage report..." -ForegroundColor $Color
    If (!($LocalTest.IsPresent)) {
        $SavePath = Join-Path -Path $PSScriptRoot -ChildPath "sqlcover"
        $coverageResults.OpenCoverXml() | Out-File $CoverageXMLPath -Encoding utf8
        $coverageResults.SaveSourceFiles($SavePath)
    }

    Else {
        # Don't save any files and bring up html report for review
        $tmpFile = Join-Path $env:TEMP "Coverage.html"
        Set-Content -Path $tmpFile -Value $coverageResults.Html2() -Force
        Invoke-Item $tmpFile
        Start-Sleep -Seconds 3
        Remove-Item $tmpFile
    }
}

# Start Coverage
If ($CodeCoverage.IsPresent) {
    $Hash = @{
        SqlInstance = $SqlInstance
        Database    = $Database
        User        = $User
        Pass        = $Pass
        IsAzureSQL  = $IsAzureSQL
        Color       = $Color
    }
    Start-CodeCoverage $Hash
}

# Generate all-in-one installer script
Get-ChildItem -Path ".\" -Filter "sp_*.sql" | Get-Content | Out-File $InstallerFile -Encoding utf8

# Run Tests
ForEach ($file in $TestFiles) {
    If (!$LocalTest.IsPresent) { Add-AppveyorTest -Name $file.BaseName -Framework NUnit -Filename $file.FullName -Outcome Running }

    $PesterResult = Invoke-Pester -Path $file.FullName -Output Detailed -PassThru
    $Outcome = "Passed"
    If ($PesterResult.FailedCount -gt 0) {
        $Outcome = "Failed"
        $FailedTests ++
    }

    If (!$LocalTest.IsPresent) { Update-AppveyorTest -Name $file.BaseName -Framework NUnit -FileName $file.FullName -Outcome $Outcome -Duration $PesterResult.UserDuration.Milliseconds }
}

# End Coverage
If ($CodeCoverage.IsPresent) {
    Complete-CodeCoverage -CoverageXMLPath $CoverageXMLPath -Color $Color
}

# Check for failures
If ($FailedTests -gt 0) {
    Throw "$FailedTests tests failed."
}
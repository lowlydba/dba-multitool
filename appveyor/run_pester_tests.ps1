using namespace System.IO.Path

param( 
    [Parameter()] 
    [bool]$LocalTest = $false,
    [string]$FilePath = "tests\run",
    [string]$CoverageXMLPath = $env:COV_REPORT,
    [string]$SqlInstance = $env:DB_INSTANCE,
    [string]$Database = $env:TARGET_DB,
    [bool]$IsAzureSQL = [System.Convert]::ToBoolean($env:AzureSQL),
    [string]$User = $env:AZURE_SQL_USER,
    [string]$Pass = $env:AZURE_SQL_PASS,
    [string]$Color = "Green",
    [switch]$CodeCoverage
)

$ErrorActionPreference = "Stop"
$TestFiles = Get-ChildItem -Path .\tests\*.Tests.ps1
$FailedTests = 0

function Start-CodeCoverage {
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
    $SQLCover.Start()
}

function Complete-CodeCoverage {
    # Stop covering 
    Write-Host "Stopping SQLCover..." -ForegroundColor $Color
    $coverageResults = $global:SQLCover.Stop()

    # Export results
    Write-Host "Generating code coverage report..." -ForegroundColor $Color
    If (!($LocalTest)) {
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
    Start-CodeCoverage
}

# Run Tests
ForEach ($file in $TestFiles) {
    Add-AppveyorTest -Name $file.BaseName -Framework NUnit -Filename $file.FullName -Outcome Running
    $PesterResult = Invoke-Pester -Path $file.FullName -Output Detailed -PassThru
    $Outcome = "Passed"
    If ($PesterResult.FailedCount -gt 0) {
        $Outcome = "Failed"
        $FailedTests ++
    }
    Update-AppveyorTest -Name $file.Name -Framework NUnit -FileName $file.FullName -Outcome $Outcome -Duration $PesterResult.UserDuration.Milliseconds
}

# End Coverage
If ($CodeCoverage.IsPresent) {
    Complete-CodeCoverage
}

# Check for failures
If ($FailedTests -gt 0) {
    Throw "$FailedTests tests failed."
}
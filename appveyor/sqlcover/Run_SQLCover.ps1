$LocalTest = $false
$SqlInstance = $env:DB_INSTANCE
$Database = "tSQLt"
$TestCommand = "EXEC tSQLt.RunAll"
$TrustedConnection = "yes"
$ConnString = "server=$SqlInstance;initial catalog=$Database;Trusted_Connection=$TrustedConnection"

# Setup files
$NugetPath = (Get-Package GOEddie.SQLCover).Source | Convert-Path
$SQLCoverRoot = Split-Path $NugetPath
$SQLCoverPath = Join-Path $SQLCoverRoot "lib"
$SQLCoverDllFullPath = Join-Path $SQLCoverPath "SQLCover.dll"

# Add DLL
Add-Type -Path $SQLCoverDllFullPath

# Start covering
$SQLCover = new-object SQLCover.CodeCoverage($ConnString, $Database)
$IsCoverStarted = $SQLCover.Start()
If ($IsCoverStarted) { Write-Host "Starting SQL Cover" }

# Run Tests
. .\appveyor\run_tsqlt_tests.ps1

# Stop covering 
$coverageResults = $SQLCover.Stop()

# Export results
$xmlPath = Join-Path -Path $PSSCriptRoot -ChildPath "Coverage.opencoverxml"
$coverageResults.OpenCoverXml() | Out-File $xmlPath -Encoding utf8
$coverageResults.SaveSourceFiles($PSScriptRoot)    
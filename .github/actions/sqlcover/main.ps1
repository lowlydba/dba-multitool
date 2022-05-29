param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("start", "stop", "install")]
    [string]$Action
)

if ($Env:RUNNER_OS -ne "Windows") {
    Write-Error "This action only supported on Windows runners." -ErrorAction "Stop"
}

# Action
if ($Action -eq "start") {
    $Package = "GOEddie.SQLCover"

    # Create output dir
    if (!(Test-Path $Env:OUTPUT_PATH)) {
        Write-Output "Creating output dir $Env:OUTPUT_PATH"
        New-Item -Path $Env:OUTPUT_PATH -ItemType "Directory"
    }

    # Install SQLCover
    Write-Output "Installing SQLCover."
    Install-Package $Package -Force -Scope "CurrentUser"

    # Start Trace
    $NugetPath = (Get-Package $Package).Source | Convert-Path
    $SQLCoverRoot = Split-Path $NugetPath
    $SQLCoverDllPath = Join-Path $SQLCoverRoot "lib\SQLCover.dll"
    Add-Type -Path $SQLCoverDllPath

    $connString = "server=$Env:SQLINSTANCE;initial catalog=$Env:DATABASE;Trusted_Connection=yes"
    $sqlCover = New-Object SQLCover.CodeCoverage($connString, $Env:DATABASE)
    $sqlCover.Start()

    # Run tests
    Invoke-Pester -Path ".\tests\*"

    # Stop
    $coverageResults = $sqlCover.Stop()

    # Save results
    $coverageResults.Cobertura() | Out-File (Join-Path -Path $Env:OUTPUT_PATH -ChildPath $Env:COV_FILE) -Encoding utf8
    $coverageResults.SaveSourceFiles($Env:OUTPUT_PATH)
}

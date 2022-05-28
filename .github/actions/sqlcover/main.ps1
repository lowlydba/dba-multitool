param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("start", "stop", "install")]
    [string]$Action,
    [string]$SqlInstance,
    [string]$Database,
    [string]$OutputPath
)

$Package = "GOEddie.SQLCover"
$endCheckSeconds = 5

if ($Env:RUNNER_OS -ne "Windows") {
    Write-Error "This action only supported on Windows runners." -ErrorAction "Stop"
}

# Always attempt to install
if ($Action -ne "stop") {
    if (!(Get-Package -Name $Package -ErrorAction "SilentlyContinue")) {
        $null = Install-Package $Package -Force -Scope "AllUsers" | Out-Null
        $NugetPath = (Get-Package $Package).Source | Convert-Path
        $SQLCoverRoot = Split-Path $NugetPath
        $SQLCoverPath = Join-Path $SQLCoverRoot "lib"
        $SQLCoverDllPath = Join-Path $SQLCoverPath "SQLCover.dll"
        Add-Type -Path $SQLCoverDllPath
    }
}

# Action
if ($Action -eq "start") {
    $connString = "server=$SqlInstance;initial catalog=$Database;Trusted_Connection=yes"

    Write-Output "Starting SQLCover."
    $sqlCover = New-Object SQLCover.CodeCoverage($connString, $Database)
    $sqlCover.Start()

    # Keep tracing until stop file exists
    Start-Job -Name "SQLCover Trace" -ScriptBlock {
        $stop = $null
        while ($null -eq $stop) {
            Start-Sleep -Seconds $endCheckSeconds
            $stop = Get-ChildItem -Path $Env:RUNNER_TEMP -Filter "stop.txt"
        }
        $coverageResults = $sqlCover.Stop()

        # Save results
        if ($null -eq $OutputPath) {
            $OutputPath = Join-Path -Path $pwd -ChildPath "sqlcover"
        }
        $coverageResults.OpenCoverXml() | Out-File (Join-Path $OutputPath "Coverage.opencoverxml") -Encoding utf8
        $coverageResults.SaveSourceFiles($OutputPath)
    }
}
elseif ($Action -eq "stop") {
    try {
        Write-Output "Stopping SQLCover."

        # Create file to trigger tracing stop
        New-Item -Path $Env:RUNNER_TEMP -Name "stop.txt"
        Start-Sleep -Seconds $endCheckSeconds
    }
    catch {
        Write-Error "Error stopping SQLCover: $($_.Exception.Message)" -ErrorAction "Stop"
    }
}

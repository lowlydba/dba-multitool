param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("start", "stop", "install")]
    [string]$Action,
    [string]$SqlInstance,
    [string]$Database,
    [string]$OutputPath
)

$Package = "GOEddie.SQLCover"
$sleepSeconds = 5
$covStopFile = "cov_stop.txt"
$covCompleteFile = "cov_complete.txt"

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
    Write-Output "Target path for results is $OutputPath"
    $sqlCover = New-Object SQLCover.CodeCoverage($connString, $Database)
    $null = $sqlCover.Start()

    # Keep tracing until stop file exists
    $null = Start-Job -Name "SQLCover Trace" -ScriptBlock {
        $stop = $null
        while ($null -eq $stop) {
            Start-Sleep -Seconds $sleepSeconds
            $stop = Get-ChildItem -Path $Env:RUNNER_TEMP -Filter $covStopFile
        }
        $coverageResults = $sqlCover.Stop()

        # Save results
        $coverageResults.Cobertura() | Out-File (Join-Path $OutputPath "coverage.xml") -Encoding utf8
        $coverageResults.SaveSourceFiles($OutputPath)

        # Signal coverage completion
        New-Item -Path $Env:RUNNER_TEMP -Name $covCompleteFile
    }
}
elseif ($Action -eq "stop") {
    try {
        Write-Output "Stopping SQLCover."

        # Create file to trigger tracing stop
        $null = New-Item -Path $Env:RUNNER_TEMP -Name $covStopFile

        # Wait for coverage to dump
        $coverageComplete = $null
        while ($null -eq $coverageComplete) {
            Start-Sleep -Seconds $sleepSeconds
            $coverageComplete = Get-ChildItem -Path $Env:RUNNER_TEMP -Filter $covCompleteFile
        }

        Write-Output "Results saved."
    }
    catch {
        Write-Error "Error stopping SQLCover: $($_.Exception.Message)" -ErrorAction "Stop"
    }
}

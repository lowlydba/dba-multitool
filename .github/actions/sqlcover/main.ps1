param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("start", "stop", "install")]
    [string]$Action,
    [string]$SqlInstance,
    [string]$Database,
    [string]$OutputPath
)


$sleepSeconds = 5
$covStopFile = "cov_stop.txt"
$covFile = "coverage.xml"

if ($Env:RUNNER_OS -ne "Windows") {
    Write-Error "This action only supported on Windows runners." -ErrorAction "Stop"
}

# Action
if ($Action -eq "start") {
    $command = {
        $Package = "GOEddie.SQLCover"
        $covStopFile = "cov_stop.txt"
        $covFile = "coverage.xml"
        $sleepSeconds = 5

        if (!(Get-Package -Name $Package -ErrorAction "SilentlyContinue")) {
            $null = Install-Package $Package -Force -Scope "AllUsers" | Out-Null
            $NugetPath = (Get-Package $Package).Source | Convert-Path
            $SQLCoverRoot = Split-Path $NugetPath
            $SQLCoverPath = Join-Path $SQLCoverRoot "lib"
            $SQLCoverDllPath = Join-Path $SQLCoverPath "SQLCover.dll"
            Add-Type -Path $SQLCoverDllPath
        }

        $connString = "server=$SqlInstance;initial catalog=$Database;Trusted_Connection=yes"
        if (!(Test-Path $OutputPath)) {
            New-Item -Path $OutputPath -ItemType "Directory"
        }
        $OutputPathFull = (Get-Item $OutputPath).FullName

        Write-Output "Starting SQLCover."
        Write-Output "Target path for results is $($OutputPathFull)"
        $sqlCover = New-Object SQLCover.CodeCoverage($connString, $Database)
        $sqlCover.Start()

        # Keep tracing until stop file exists
        $stop = $null
        while ($null -eq $stop) {
            Start-Sleep -Seconds $sleepSeconds
            $stop = Get-ChildItem -Path $Env:RUNNER_TEMP -Filter $covStopFile

            $coverageResults = $sqlCover.Stop()

            # Save results
            $coverageResults.Cobertura() | Out-File (Join-Path -Path $OutputPath -ChildPath $covFile) -Encoding utf8
            $coverageResults.SaveSourceFiles($OutputPath)
        }
    }

    # Embed the script block with " escaped as \"
    Start-Process powershell -Verb "RunAs" -ArgumentList "-NoExit -Command & { $($command -replace '"', '\"') }"
}
elseif ($Action -eq "stop") {
    try {
        Write-Output "Stopping SQLCover."

        # Create file to trigger tracing stop
        $null = New-Item -Path $Env:RUNNER_TEMP -Name $covStopFile

        # Wait for coverage to dump
        Write-Output "Waiting for coverage results..."
        $coverageComplete = $null
        while ($null -eq $coverageComplete) {
            $coverageComplete = Get-ChildItem -Path $OutputPath -Filter $covFile
            Start-Sleep -Seconds $sleepSeconds
        }

        Write-Output "Results saved."
    }
    catch {
        Write-Error "Error stopping SQLCover: $($_.Exception.Message)" -ErrorAction "Stop"
    }
}

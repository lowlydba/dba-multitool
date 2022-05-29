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
    $command = {
        $Package = "GOEddie.SQLCover"

        $null = Install-Package $Package -Force -Scope "CurrentUser" | Out-Null
        $NugetPath = (Get-Package $Package).Source | Convert-Path
        $SQLCoverRoot = Split-Path $NugetPath
        $SQLCoverPath = Join-Path $SQLCoverRoot "lib"
        $SQLCoverDllPath = Join-Path $SQLCoverPath "SQLCover.dll"
        Add-Type -Path $SQLCoverDllPath

        $connString = "server=$Env:SQLINSTANCE;initial catalog=$Env:DATABASE;Trusted_Connection=yes"
        if (!(Test-Path $Env:OUTPUT_PATH)) {
            New-Item -Path $Env:OUTPUT_PATH -ItemType "Directory"
        }
        $sqlCover = New-Object SQLCover.CodeCoverage($connString, $Env:DATABASE)
        $sqlCover.Start()

        # Trace until stop file exists
        $stop = $null
        while ($null -eq $stop) {
            Start-Sleep -Seconds $Env:SLEEP_SEC
            $stop = Get-ChildItem -Path $Env:RUNNER_TEMP -Filter $Env:STOP_FILE
        }
        $coverageResults = $sqlCover.Stop()

        # Save results
        $coverageResults.Cobertura() | Out-File (Join-Path -Path $Env:OUTPUT_PATH -ChildPath $Env:COV_FILE) -Encoding utf8
        $coverageResults.SaveSourceFiles($Env:OUTPUT_PATH)
    }

    # Embed the script block with " escaped as \"
    Start-Process pwsh -ArgumentList "-NoInteractive -Command & { $($command -replace '"', '\"')}"
}
elseif ($Action -eq "stop") {
    try {
        Write-Output "Stopping SQLCover."

        # Create file to trigger tracing stop
        $null = New-Item -Path $Env:RUNNER_TEMP -Name $Env:STOP_FILE

        # Wait for coverage to dump
        Write-Output "Waiting for coverage results..."
        $coverageComplete = $null
        while ($null -eq $coverageComplete) {
            $coverageComplete = Get-ChildItem -Path $Env:OUTPUT_PATH -Filter $Env:COV_FILE
            Start-Sleep -Seconds $Env:SLEEP_SEC
        }

        Write-Output "Results saved."
    }
    catch {
        Write-Error "Error stopping SQLCover: $($_.Exception.Message)" -ErrorAction "Stop"
    }
}

param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("start", "stop", "install")]
    [string]$Action,
    [string]$SqlInstance,
    [string]$Database,
    [string]$OutputPath
)

if (!$IsWindows) {
    Write-Error "This action only supported on Windows runners." -ErrorAction "Stop"
}

# Always attempt to install
if (!(Get-Package -Name GOEddie.SQLCover -ErrorAction SilentlyContinue)) {
    $null = Install-Package GOEddie.SQLCover -Force | Out-Null
    $NugetPath = (Get-Package GOEddie.SQLCover).Source | Convert-Path
    $SQLCoverRoot = Split-Path $NugetPath
    $SQLCoverPath = Join-Path $SQLCoverRoot "lib"
    $SQLCoverDllPath = Join-Path $SQLCoverPath "SQLCover.dll"
    Add-Type -Path $SQLCoverDllPath
}

# Action
if ($Action -eq "start") {
    $connString = "server=$SqlInstance;initial catalog=$Database;Trusted_Connection=yes"

    Write-Output "Starting SQLCover."
    $global:sqlCover = New-Object SQLCover.CodeCoverage($connString, $Database)
    $null = $sqlCover.Start()

}
elseif ($Action -eq "stop") {
    Write-Output "Stopping SQLCover."
    $coverageResults = $global:SQLCover.Stop()

    Write-Output "Generating code coverage report."
    if ($null -eq $OutputPath) {
        $OutputPath = Join-Path -Path $Env:GITHUB_WORKSPACE -ChildPath "sqlcover"
    }
    $coverageResults.OpenCoverXml() | Out-File (Join-Path $OutputPath "Coverage.opencoverxml") -Encoding utf8
    $coverageResults.SaveSourceFiles($OutputPath)
}

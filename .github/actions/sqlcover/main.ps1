param(
    [Parameter(Mandatory = $true)]
    [string]$Database,
    [Parameter(Mandatory = $true)]
    [string]$SqlInstance,
    [string]$Package = "GOEddie.SQLCover",
    [Parameter(Mandatory = $true)]
    [string]$OutputFile
)

if ($Env:RUNNER_OS -ne "Windows") {
    Write-Error "This action only supported on Windows runners." -ErrorAction "Stop"
}

# Install SQLCover
Write-Output "Installing SQLCover."
$null = Install-Package $Package -Force -Scope "CurrentUser"
$NugetPath = (Get-Package $Package).Source | Convert-Path
$SQLCoverRoot = Split-Path $NugetPath
$SQLCoverDllPath = Join-Path $SQLCoverRoot "lib\SQLCover.dll"
Add-Type -Path $SQLCoverDllPath

$connString = "server=$SqlInstance;Trusted_Connection=yes"
$sqlCover = New-Object SQLCover.CodeCoverage($connString, $Database)
$null = $sqlCover.Start()

# Run tests
Invoke-Pester -Path ".\tests\*"

# Stop
Write-Output "Stopping SQL Cover."
$coverageResults = $sqlCover.Stop()

# Save results
[xml]$coberturaXml = $coverageResults.Cobertura()
$OutputFullPath = Join-Path -Path "." -ChildPath $OutputFile
Write-Output "Saving Cobertura report to $OutputFullPath"

# Fix missing filename with best-effort value
# https://github.com/GoEddie/SQLCover/issues/79
foreach ($class in  $coberturaXml.coverage.packages.package.classes.class) {
    $class.filename = $class.Name
}
$coberturaXml.Save($OutputFullPath)

# HTML artifact
$HtmlFullPath = Join-Path -Path "." -ChildPath "coverage.html"
Write-Output "Saving HTML report to $HtmlFullPath"
Set-Content -Path $HtmlFullPath -Value $coverageResults.Html2() -Force

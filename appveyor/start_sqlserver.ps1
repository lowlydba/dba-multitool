#PSScriptAnalyzer rule excludes
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '')]

param(
    [Parameter()]
    [string]$Color = "Green"
)

Write-Host "Starting SQL Server" -ForegroundColor $Color

$SQLInstance = $env:MSSQL;
Start-Service "MSSQL`$$SQLInstance";
#PSScriptAnalyzer rule excludes
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '')]

param(
    [Parameter()]
    [string]$Color = "Green"
)

Write-Host "Starting SQL Server" -ForegroundColor $Color

$Instance = $env:MSSQL;
Start-Service "MSSQL`$$Instance";

# Set max memory to correct value
Set-DbaMaxMemory -SqlInstance "localhost" | Out-Null
Set-DbaMaxDop -SqlInstance "localhost" -MaxDop 1
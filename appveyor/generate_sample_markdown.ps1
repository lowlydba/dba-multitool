#PSScriptAnalyzer rule excludes
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '')]

param(
    [Parameter()]
    [string]$SqlInstance = $env:DB_INSTANCE,
    [string]$UtilityDatabase = $env:TARGET_DB,
    [string]$Color = "Green"
)

$ErrorActionPreference = "Stop";
$Url = "https://github.com/Microsoft/sql-server-samples/releases/download/wide-world-importers-v1.0/WideWorldImporters-Full.bak"
$BackupPath = "C:\WideWorldImporters-Full.bak"
$SampleDatabase = "WideWorldImporters"
$SampleMarkdown = "docs/assets/$SampleDatabase.md"

Write-Host "Generating $SampleDatabase markdown sample..." -ForegroundColor $Color

# Download and restore WideWorldImporters sample database
If (!(Get-DbaDatabase -SqlInstance $SqlInstance -Database $SampleDatabase -WarningAction SilentlyContinue)) {
    Invoke-WebRequest -Uri $Url -OutFile $BackupPath

    If (Test-Path $BackupPath) { Restore-DbaDatabase -SqlInstance $SqlInstance -DatabaseName $SampleDatabase -Path $BackupPath -WithReplace | Out-Null }
    Else { Write-Error "$SampleDatabase backup failed to download properly." }
}

# Generate documentation
$Query = "EXEC sp_doc @DatabaseName = '$SampleDatabase';"
Invoke-DbaQuery -SqlInstance $SqlInstance -Database $UtilityDatabase -Query $Query -As SingleValue | Out-File $SampleMarkdown

# Remove footer to avoid eternal appveyor build loop from file diffs
$Temp = Get-Content $SampleMarkdown
$Temp[0..($Temp.Length - 4)] | Out-File $SampleMarkdown -Encoding utf8
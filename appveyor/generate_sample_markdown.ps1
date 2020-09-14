param( 
    [Parameter()] 
    [string]$SqlInstance = $env:DB_INSTANCE,
    [bool]$IsAzureSQL = [System.Convert]::ToBoolean($env:AzureSQL),
    [string]$User = $env:AZURE_SQL_USER,
    [string]$Pass = $env:AZURE_SQL_PASS,
    [string]$Color = "Green"
    )

Write-Host "Generating WideWorldImporters markdown sample..." -ForegroundColor $Color

$ErrorActionPreference = "Stop";
$Url = "https://github.com/Microsoft/sql-server-samples/releases/download/wide-world-importers-v1.0/WideWorldImporters-Full.bak"
$BackupPath = "C:\WideWorldImporters-Full.bak"
$Database = "WideWorldImporters"
$master = "master"

# Download and restore WideWorldImporters sample database
If (!(Get-DbaDatabase -SqlInstance $SqlInstance -Database $Database)) {
    Invoke-WebRequest -Uri $Url -OutFile $BackupPath

    If (Test-Path $BackupPath) { Restore-DbaDatabase -SqlInstance $SqlInstance -DatabaseName $Database -Path $BackupPath -WithReplace }
    Else { Write-Error "WideWorldImporters backup failed to download properly." }
}

# Generate documentation
sqlcmd -S $SqlInstance -d $master -Q "EXEC sp_doc @DatabaseName = 'WideWorldImporters';" -o "docs/WideWorldImporters.md" -y 0
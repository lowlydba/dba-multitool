param( 
    [Parameter()] 
    [string]$SqlInstance = $env:DB_INSTANCE,
    [string]$Database = $env:TARGET_DB,
    [bool]$IsAzureSQL = [System.Convert]::ToBoolean($env:AzureSQL),
    [string]$User = $env:AZURE_SQL_USER,
    [string]$Pass = $env:AZURE_SQL_PASS,
    [string]$Color = "Green",
    [string]$InputFile = "install_dba-multitool.sql"
    )

Write-Host "Installing DBA MultiTool scripts..." -ForegroundColor $Color

$ErrorActionPreference = "Stop";

If ($IsAzureSQL) {
    Invoke-SqlCmd2 -ServerInstance $SqlInstance -Database $Database -InputFile $InputFile -Username $User -Password $Pass
}
Else {
    Invoke-SqlCmd2 -ServerInstance $SqlInstance -Database $Database -InputFile $InputFile

}

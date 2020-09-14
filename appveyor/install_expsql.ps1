param( 
    [Parameter()] 
    [string]$SqlInstance = $env:DB_INSTANCE,
    [string]$Database = $env:TARGET_DB,
    [bool]$IsAzureSQL = [System.Convert]::ToBoolean($env:AzureSQL),
    [string]$User = $env:AZURE_SQL_USER,
    [string]$Pass = $env:AZURE_SQL_PASS,
    [string]$Color = "Green"
    )

Write-Host "Installing ExpressSQL scripts..." -ForegroundColor $Color

$ErrorActionPreference = "Stop";

If ($IsAzureSQL) {
    Invoke-SqlCmd -ServerInstance $SqlInstance -Database $Database -InputFile "install_expsql.sql" -Username $User -Password $Pass
}
Else {
    Invoke-SqlCmd -ServerInstance $SqlInstance -Database $Database -InputFile "install_expsql.sql"

}

param( 
    [Parameter()] 
    [string]$FilePath = "tests\run",
    [string]$SqlInstance = $env:DB_INSTANCE,
    [string]$Database = $env:TARGET_DB,
    [bool]$IsAzureSQL = $env:AzureSQL,
    [string]$User = $env:AZURE_SQL_USER,
    [string]$Pass = $env:AZURE_SQL_PASS,
    [string]$Color = "Green"
    )

Write-Host "Running tSQLt Tests..." -ForegroundColor $Color
Try {
    If ($IsAzureSQL) {
        ForEach ($filename in Get-Childitem -Path $FilePath -Filter "*.sql") {
            Invoke-SqlCmd -ServerInstance $SqlInstance -Database $Database -InputFile $filename.fullname -Verbose -Username $User -Password $Pass | Out-Null
        }
    }
    Else {
        ForEach ($filename in Get-Childitem -Path $FilePath -Filter "*.sql") {
            Invoke-SqlCmd -ServerInstance $SqlInstance -Database $Database -InputFile $filename.fullname -Verbose | Out-Null
        }
    }
}
Catch {
    Write-Error "Unit test error!"
}
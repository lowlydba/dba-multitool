param( 
    [Parameter()] 
    [string]$SqlInstance = $env:DB_INSTANCE,
    [string]$Database = $env:TARGET_DB,
    [string]$TestPath = "tests\build",
    [bool]$IsAzureSQL = $env:AzureSQL,
    [string]$User = $env:AZURE_SQL_USER,
    [string]$Pass = $env:AZURE_SQL_PASS,
    $Color = "Green"
    )

Write-Host "Building tSQLt Tests..." -ForegroundColor $Color

If ($IsAzureSQL) {
    ForEach ($filename in Get-Childitem -Path $TestPath -Filter "*.sql") {
        Invoke-SqlCmd -ServerInstance $SqlInstance -Database $Database -InputFile $filename.fullname -Username $User -Password $Pass
    }
}
Else {
    ForEach ($filename in Get-Childitem -Path $TestPath -Filter "*.sql") {
        Invoke-SqlCmd -ServerInstance $SqlInstance -Database $Database -InputFile $filename.fullname
    }
}

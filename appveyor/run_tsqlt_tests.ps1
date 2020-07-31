Write-Host "Run tSQLt Tests"

ForEach ($filename in Get-Childitem -Path $env:TSQLTTESTPATH -Filter "*.sql") {
    Invoke-SqlCmd -ServerInstance $env:DB_INSTANCE -Database $env:TARGET_DB -InputFile $filename.fullname -Username $env:MSSQL_LOGIN -Password $env:MSSQL_PASS -Verbose | Out-Null
}
Write-Host "Building tSQLt Tests"

ForEach ($filename in Get-Childitem -Path $env:TSQLTBUILDPATH -Filter "*.sql") {
    Invoke-SqlCmd -ServerInstance $env:DB_INSTANCE -Database $env:TARGET_DB -InputFile $filename.fullname -Username $env:MSSQL_LOGIN -Password $env:MSSQL_PASS
}
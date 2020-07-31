Write-Host "Installing ExpressSQL Scripts"

Invoke-SqlCmd -ServerInstance $env:DB_INSTANCE -Database $env:TARGET_DB -InputFile "install_expsql.sql" -Username $env:MSSQL_LOGIN -Password $env:MSSQL_PASS

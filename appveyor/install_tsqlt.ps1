Write-Host "Installing tSQLt"

$CLRScript = Join-Path $env:CLONE_FOLDER $env:TSQLTSETCLR
$CreateDBScript = Join-Path $env:CLONE_FOLDER $env:TSQLTCREATEDB
$tSQLtInstallScript = Join-Path $env:CLONE_FOLDER $env:TSQLTINSTALL

Invoke-SqlCmd –ServerInstance $env:DB_INSTANCE -Database "master" -InputFile $clrscript -Username $env:MSSQL_LOGIN -Password $env:MSSQL_PASS -Verbose | Out-Null
Invoke-SqlCmd –ServerInstance $env:DB_INSTANCE -Database "master" -InputFile $CreateDBScript -Username $env:MSSQL_LOGIN -Password $env:MSSQL_PASS -Verbose | Out-Null
Invoke-SqlCmd –ServerInstance $env:DB_INSTANCE -Database $env:TARGET_DB -InputFile $tSQLtInstallScript -Username $env:MSSQL_LOGIN -Password $env:MSSQL_PASS
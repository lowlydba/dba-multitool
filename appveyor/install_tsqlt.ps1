param( 
    [Parameter()] 
    $SqlInstance = $env:DB_INSTANCE,
    $Database = $env:TARGET_DB,
    $CLRScript = "tests\tSQLt\SetClrEnabled.sql",
    $CreateDBScript = "tests\tSQLt\CreateDatabase.sql",
    $tSQLtInstallScript = "tests\tSQLt\tSQLt.class.sql",
    $Color = "Green"
    )
$Master = "master"

Write-Host "Installing tSQLt..." -ForegroundColor $Color

Invoke-SqlCmd -ServerInstance $SqlInstance -Database $Master -InputFile $clrscript | Out-Null
Invoke-SqlCmd -ServerInstance $SqlInstance -Database $Master -InputFile $CreateDBScript | Out-Null
Invoke-SqlCmd -ServerInstance $SqlInstance -Database $Database -InputFile $tSQLtInstallScript
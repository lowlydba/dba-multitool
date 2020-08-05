param( 
    [Parameter()] 
    [String]$SqlInstance = $env:DB_INSTANCE,
    [String]$Database = $env:TARGET_DB,
    [String]$CLRScript = "tests\tSQLt\SetClrEnabled.sql",
    [String]$CreateDBScript = "tests\tSQLt\CreateDatabase.sql",
    [String]$tSQLtInstallScript = "tests\tSQLt\tSQLt.class.sql",
    [String]$Color = "Green",
    [String]$Master = "master"
    )

Write-Host "Installing tSQLt..." -ForegroundColor $Color

Invoke-SqlCmd -ServerInstance $SqlInstance -Database $Master -InputFile $clrscript | Out-Null
Invoke-SqlCmd -ServerInstance $SqlInstance -Database $Master -InputFile $CreateDBScript | Out-Null
Invoke-SqlCmd -ServerInstance $SqlInstance -Database $Database -InputFile $tSQLtInstallScript
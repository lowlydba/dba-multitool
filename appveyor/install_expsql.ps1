param( 
    [Parameter()] 
    $SqlInstance = $env:DB_INSTANCE,
    $Database = $env:TARGET_DB,
    $Color = "Green"
    )

Write-Host "Installing ExpressSQL scripts..." -ForegroundColor $Color

Invoke-SqlCmd -ServerInstance $SqlInstance -Database $Database -InputFile "install_expsql.sql"

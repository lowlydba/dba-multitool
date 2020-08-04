param( 
    [Parameter()] 
    $SqlInstance = $env:DB_INSTANCE,
    $Database = $env:TARGET_DB,
    $TestPath = "tests\build",
    $Color = "Green"
    )

Write-Host "Building tSQLt Tests..." -ForegroundColor $Color

ForEach ($filename in Get-Childitem -Path $TestPath -Filter "*.sql") {
    Invoke-SqlCmd -ServerInstance $SqlInstance -Database $Database -InputFile $filename.fullname
}
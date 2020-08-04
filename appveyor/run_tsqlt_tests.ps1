param( 
    [Parameter()] 
    $FilePath = "tests\run",
    $SqlInstance = $env:DB_INSTANCE,
    $Database = $env:TARGET_DB,
    $Color = "Green"
    )

Write-Host "Running tSQLt Tests..." -ForegroundColor $Color

ForEach ($filename in Get-Childitem -Path $FilePath -Filter "*.sql") {
    Invoke-SqlCmd -ServerInstance $SqlInstance -Database $Database -InputFile $filename.fullname -Verbose | Out-Null
}
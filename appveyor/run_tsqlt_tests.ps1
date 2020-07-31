param( 
    [Parameter()] 
    $FilePath = $env:TSQLTTESTPATH,
    $SqlInstance = $env:DB_INSTANCE,
    $Database = $env:TARGET_DB,
    $SqlUser = $env:MSSQL_LOGIN,
    $SqlPass = $env:MSSQL_PASS,
    $SQLAuth = $true
    )

Write-Host "Run tSQLt Tests"

ForEach ($filename in Get-Childitem -Path $FilePath -Filter "*.sql") {
    If ($SQLAuth) {
        Invoke-SqlCmd -ServerInstance $SqlInstance -Database $Database -InputFile $filename.fullname -Username $SqlUser -Password $SqlPass -Verbose | Out-Null
    }
    Else {
        Invoke-SqlCmd -ServerInstance $SqlInstance -Database $Database -InputFile $filename.fullname -Verbose | Out-Null
    }
}
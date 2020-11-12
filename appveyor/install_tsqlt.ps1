param( 
    [Parameter()] 
    [String]$SqlInstance = $env:DB_INSTANCE,
    [String]$Database = $env:TARGET_DB,
    [String]$CLRScript = "tests\tSQLt\SetClrEnabled.sql",
    [String]$CreateDBScript = "tests\tSQLt\CreateDatabase.sql",
    [String]$tSQLtInstallScript = "tests\tSQLt\tSQLt.class.sql",
    [String]$Color = "Green",
    [String]$Master = "master",
    [string]$User = $env:AZURE_SQL_USER,
    [string]$Pass = $env:AZURE_SQL_PASS,
    [bool]$IsAzureSQL = [System.Convert]::ToBoolean($env:AzureSQL)
    )

Write-Host "Installing tSQLt..." -ForegroundColor $Color

If ($IsAzureSQL) {
    $PWord = ConvertTo-SecureString -String $Pass -AsPlainText -Force
    $Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $PWord

    Invoke-SqlCmd2 -ServerInstance $SqlInstance -Database $Database -InputFile $tSQLtInstallScript -Verbose -Credential $Credential
}
Else {
    Invoke-SqlCmd2 -ServerInstance $SqlInstance -Database $Master -InputFile $clrscript | Out-Null
    Invoke-SqlCmd2 -ServerInstance $SqlInstance -Database $Master -InputFile $CreateDBScript | Out-Null
    Invoke-SqlCmd2 -ServerInstance $SqlInstance -Database $Database -InputFile $tSQLtInstallScript -Verbose
}

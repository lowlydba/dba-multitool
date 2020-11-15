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

$Hash = @{
    SqlInstance     = $SqlInstance
    Database        = $Database  
    EnableException = $true
}

If ($IsAzureSQL) {
    $SecPass = ConvertTo-SecureString -String $Pass -AsPlainText -Force
    $Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $SecPass
    $Hash.add("SqlCredential", $Credential)

    Invoke-DbaQuery @hash -File $tSQLtInstallScript
}

Else {
    Invoke-DbaQuery -SqlInstance $SqlInstance -Database $Master -File $clrscript | Out-Null
    Invoke-DbaQuery -SqlInstance $SqlInstance -Database $Master -File $CreateDBScript | Out-Null
    Invoke-DbaQuery @Hash -File $tSQLtInstallScript -MessagesToOutput
}

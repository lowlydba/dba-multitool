param( 
    [Parameter()] 
    [String]$SqlInstance = $env:DB_INSTANCE,
    [String]$Database = $env:TARGET_DB,
    [String]$tSQLtInstallScript = "tests\tSQLt\tSQLt.class.sql",
    [string]$User = $env:AZURE_SQL_USER,
    [string]$Pass = $env:AZURE_SQL_PASS,
    [String]$Color = "Green"
    )

Write-Host "Installing tSQLt..." -ForegroundColor $Color

$PWord = ConvertTo-SecureString -String $Pass -AsPlainText -Force
$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $PWord

Invoke-SqlCmd2 -ServerInstance $SqlInstance -Database $Database -InputFile $tSQLtInstallScript -Credential $Credential
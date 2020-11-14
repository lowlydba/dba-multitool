param( 
    [Parameter()] 
    [string]$SqlInstance = $env:DB_INSTANCE,
    [string]$Database = $env:TARGET_DB,
    [bool]$IsAzureSQL = [System.Convert]::ToBoolean($env:AzureSQL),
    [string]$User = $env:AZURE_SQL_USER,
    [string]$Pass = $env:AZURE_SQL_PASS,
    [string]$Color = "Green",
    [string]$InputFile = "install_dba-multitool.sql"
)

Write-Host "Installing DBA MultiTool scripts..." -ForegroundColor $Color

$ErrorActionPreference = "Stop";

If ($IsAzureSQL) {
    $PWord = ConvertTo-SecureString -String $Pass -AsPlainText -Force
    $Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $PWord

    Invoke-DbaQuery -SqlInstance $SqlInstance -Database $Database -File $InputFile -SqlCredential $Credential
}

Else {
    Invoke-DbaQuery -SqlInstance $SqlInstance -Database $Database -File $InputFile

}

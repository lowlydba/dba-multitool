param( 
    [Parameter()] 
    [string]$FilePath = "tests\run",
    [string]$SqlInstance = $env:DB_INSTANCE,
    [string]$Database = $env:TARGET_DB,
    [bool]$IsAzureSQL = [System.Convert]::ToBoolean($env:AzureSQL),
    [string]$User = $env:AZURE_SQL_USER,
    [string]$Pass = $env:AZURE_SQL_PASS,
    [string]$Color = "Green"
)

$ErrorActionPreference = "Stop"

Write-Host "Running tSQLt Tests..." -ForegroundColor $Color

Try {
    If ($IsAzureSQL) {
        $PWord = ConvertTo-SecureString -String $Pass -AsPlainText -Force
        $Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $PWord

        ForEach ($filename in Get-ChildItem -Path $FilePath -Filter "*.sql") {
            Invoke-DbaQuery -SqlInstance $SqlInstance -Database $Database -File $filename.fullname -Verbose -Credential $Credential | Out-Null
        }
    }
    Else {
        ForEach ($filename in Get-ChildItem -Path $FilePath -Filter "*.sql") {
            Invoke-DbaQuery -SqlInstance $SqlInstance -Database $Database -File $filename.fullname -Verbose | Out-Null
        }
    }
}

Catch {
    Write-Error "Unit test error!"
}
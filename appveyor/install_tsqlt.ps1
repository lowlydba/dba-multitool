param( 
    [Parameter()] 
    [String]$SqlInstance = $env:DB_INSTANCE,
    [String]$Database = $env:TARGET_DB,
    [String]$Color = "Green",
    [string]$User = $env:AZURE_SQL_USER,
    [string]$Pass = $env:AZURE_SQL_PASS,
    [bool]$IsAzureSQL = [System.Convert]::ToBoolean($env:AzureSQL)
)

Write-Host "Downloading and installing tSQLt..." -ForegroundColor $Color

$DownloadUrl = "http://tsqlt.org/download/tsqlt/"
$TempPath = [System.IO.Path]::GetTempPath()
$ZipFile = Join-Path $TempPath "tSQLt.zip"
$ZipFolder = Join-Path $TempPath "tSQLt"
$SetupFile = Join-Path $ZipFolder "PrepareServer.sql"
$InstallFile = Join-Path $ZipFolder "tSQLt.class.sql"
$CreateDbQuery = "CREATE DATABASE [tsqlt];"

# Download
Try {
    Invoke-WebRequest -Uri $DownloadUrl -OutFile $ZipFile -ErrorAction Stop -UseBasicParsing
    Expand-Archive -Path $ZipFile -DestinationPath $TempPath -Force
}

Catch {
    Write-Error -Message "Error downloading tSQLt - try manually fetching from $DownloadUrl"
}

$Hash = @{
    SqlInstance     = $SqlInstance
    Database        = $Database  
    EnableException = $true
}

# Install
If ($IsAzureSQL) {
    $SecPass = ConvertTo-SecureString -String $Pass -AsPlainText -Force
    $Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $SecPass
    $Hash.add("SqlCredential", $Credential)
}

Else {
    Invoke-DbaQuery -SqlInstance $SqlInstance -Database "master" -Query $CreateDbQuery
    Invoke-DbaQuery @Hash -File $SetupFile
}

Invoke-DbaQuery @Hash -File $InstallFile

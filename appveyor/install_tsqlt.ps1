#PSScriptAnalyzer rule excludes
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '')]

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

$DownloadUrl = "http://tsqlt.org/download/tsqlt/?version="
$TempPath = [System.IO.Path]::GetTempPath()
$ZipFile = Join-Path $TempPath "tSQLt.zip"
$ZipFolder = Join-Path $TempPath "tSQLt"
$InstallFile = Join-Path $ZipFolder "tSQLt.class.sql"

$CLRSecurityQuery = "
/* Turn off CLR Strict for 2017+ fix */
IF EXISTS (SELECT 1 FROM sys.configurations WHERE name = 'clr strict security')
BEGIN
	EXEC sp_configure 'show advanced options', 1;
	RECONFIGURE;

	EXEC sp_configure 'clr strict security', 0;
	RECONFIGURE;
END
GO"

$Hash = @{
    SqlInstance     = $SqlInstance
    Database        = $Database
    EnableException = $true
}

# Cant use latest for Azure yet 
# https://github.com/LowlyDBA/dba-multitool/issues/165
If ($IsAzureSQL) {
    $Version = "1-0-5873-27393"
    $DownloadUrl = $DownloadUrl + $Version
    #$SetupFile = Join-Path $ZipFolder "SetClrEnabled.sql" # Used for 1.0.5873.27393

    # Azure creds
    $SecPass = ConvertTo-SecureString -String $Pass -AsPlainText -Force
    $Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $SecPass
    $Hash.add("SqlCredential", $Credential)
}

Else {
    $CreateDbQuery = "CREATE DATABASE [tSQLt];"
    $SetupFile = Join-Path $ZipFolder "PrepareServer.sql" 
}

# Download
Try {
    Invoke-WebRequest -Uri $DownloadUrl -OutFile $ZipFile -ErrorAction Stop -UseBasicParsing
    Expand-Archive -Path $ZipFile -DestinationPath $ZipFolder -Force
}

Catch {
    Write-Error -Message "Error downloading tSQLt - try manually fetching from $DownloadUrl"
}

# Prep
If (-not $IsAzureSQL) {
    Invoke-DbaQuery -SqlInstance $SqlInstance -Database "master" -Query $CreateDbQuery
    Invoke-Command -ScriptBlock { sqlcmd -S $SqlInstance -d $Database -i $SetupFile } | Out-Null
    Invoke-DbaQuery @Hash -Query $CLRSecurityQuery
}

# Install
Invoke-DbaQuery @Hash -File $InstallFile

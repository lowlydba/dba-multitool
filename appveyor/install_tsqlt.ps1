#PSScriptAnalyzer rule excludes
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '')]

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

# BaseUrl gets the latest version by default - blocked by https://github.com/LowlyDBA/dba-multitool/issues/165 
$Version = "1-0-5873-27393"
$DownloadUrl = "http://tsqlt.org/download/tsqlt/?version=" + $Version
$TempPath = [System.IO.Path]::GetTempPath()
$ZipFile = Join-Path $TempPath "tSQLt.zip"
$ZipFolder = Join-Path $TempPath "tSQLt"
#$SetupFile = Join-Path $ZipFolder "PrepareServer.sql" # Used in latest version after 1.0.5873.27393
$SetupFile = Join-Path $ZipFolder "SetClrEnabled.sql"
$InstallFile = Join-Path $ZipFolder "tSQLt.class.sql"
$CreateDbQuery = "CREATE DATABASE [tSQLt];"
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


# Download
Try {
    Invoke-WebRequest -Uri $DownloadUrl -OutFile $ZipFile -ErrorAction Stop -UseBasicParsing
    Expand-Archive -Path $ZipFile -DestinationPath $ZipFolder -Force
}

Catch {
    Write-Error -Message "Error downloading tSQLt - try manually fetching from $DownloadUrl"
}

$Hash = @{
    SqlInstance     = $SqlInstance
    Database        = $Database
    EnableException = $true
}

# Setup
If ($IsAzureSQL) {
    $SecPass = ConvertTo-SecureString -String $Pass -AsPlainText -Force
    $Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $SecPass
    $Hash.add("SqlCredential", $Credential)
}

Else {
    Invoke-DbaQuery -SqlInstance $SqlInstance -Database "master" -Query $CreateDbQuery
    # DbaQuery doesn't play nice with the setup script GOs - default back to sqlcmd
    Invoke-Command -ScriptBlock { sqlcmd -S $SqlInstance -d $Database -i $SetupFile } | Out-Null
    Invoke-DbaQuery @Hash -Query $CLRSecurityQuery
}

# Install
Invoke-DbaQuery @Hash -File $InstallFile

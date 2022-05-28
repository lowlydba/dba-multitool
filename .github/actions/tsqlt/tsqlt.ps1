param(
    [Parameter()]
    [string]$SqlInstance,
    [string]$Database,
    [string]$Version
    # [string]$User = $env:AZURE_SQL_USER,
    # [string]$Pass = $env:AZURE_SQL_PASS,
    # [bool]$IsAzureSQL = [System.Convert]::ToBoolean($env:AzureSQL)
)

Write-Output "Downloading and installing tSQLt..."

$DownloadUrl = "http://tsqlt.org/download/tsqlt/?version="
$TempPath = [System.IO.Path]::GetTempPath()
$ZipFile = Join-Path $TempPath "tSQLt.zip"
$ZipFolder = Join-Path $TempPath "tSQLt"
$InstallFile = Join-Path $ZipFolder "tSQLt.class.sql"
$SetupFile = Join-Path $ZipFolder "PrepareServer.sql"
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
Invoke-WebRequest -Uri $DownloadUrl -OutFile $ZipFile -ErrorAction Stop -UseBasicParsing
Expand-Archive -Path $ZipFile -DestinationPath $ZipFolder -Force

# Install
if ($IsLinux) {
    sqlcmd -S $SqlInstance -d $Database -q $CLRSecurityQuery
    sqlcmd -S $SqlInstance -d $Database -i $SetupFile
    sqlcmd -S $SqlInstance -d $Database -i $InstallFile
}
elseif ($IsWindows) {
    $connSplat = @{
        ServerInstance = $SqlInstance
        Database = $Database
    }
    if (!(Get-SqlDatabase -ServerInstance $SqlInstance -Name $Database)) {
        Write-Error "Database '$Database' not found." -ErrorAction 'Stop'
    }
    $null = Invoke-SqlCmd @connSplat -Query $CLRSecurityQuery
    Invoke-SqlCmd @connSplat -InputFile $SetupFile
    Invoke-SqlCmd @connSplat -InputFile $InstallFile
}
else {
    Write-Error "Only Linux and Windows operation systems supported."
}

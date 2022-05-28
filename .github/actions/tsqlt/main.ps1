param(
    [Parameter()]
    [string]$SqlInstance,
    [string]$Database,
    [string]$Version
    # [string]$User,
    # [string]$Pass,
)

$DownloadUrl = "http://tsqlt.org/download/tsqlt/?version=$Version"
$TempPath = [System.IO.Path]::GetTempPath()
$zipFile = Join-Path $TempPath "tSQLt.zip"
$zipFolder = Join-Path $TempPath "tSQLt"
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
try {
    Write-Output "Downloading from $DownloadUrl ..."
    Invoke-WebRequest -Uri $DownloadUrl -OutFile $zipFile -ErrorAction Stop -UseBasicParsing
    Expand-Archive -Path $zipFile -DestinationPath $zipFolder -Force
    Write-Output "Download complete."
}
catch {
    Write-Error "Unable to download & extract tSQLt from '$DownloadUrl'. Ensure version is valid."
}

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
        Write-Error "Database '$Database' not found." -ErrorAction "Stop"
    }
    $null = Invoke-SqlCmd @connSplat -Query $CLRSecurityQuery
    Invoke-SqlCmd @connSplat -InputFile $SetupFile
    Invoke-SqlCmd @connSplat -InputFile $InstallFile
}
else {
    Write-Error "Only Linux and Windows operation systems supported." -ErrorAction "Stop"
}
Write-Output "Installation completed."

param(
    [Parameter()]
    [string]$SqlInstance,
    [string]$Database,
    [string]$Version,
    [string]$TempDir = $Env:RUNNER_TEMP
    # [string]$User,
    # [string]$Pass,
)

$DownloadUrl = "http://tsqlt.org/download/tsqlt/?version=$Version"
$zipFile = Join-Path $TempDir "tSQLt.zip"
$zipFolder = Join-Path $TempDir "tSQLt"
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
    Write-Output "Downloading $DownloadUrl"
    Invoke-WebRequest -Uri $DownloadUrl -OutFile $zipFile -ErrorAction Stop -UseBasicParsing
    Expand-Archive -Path $zipFile -DestinationPath $zipFolder -Force
    $installFile = (Get-ChildItem $zipFolder -Filter "tSQLt.class.sql").FullName
    $setupFile = (Get-ChildItem $zipFolder -Filter "PrepareServer.sql").FullName
    Write-Output "Download complete."
}
catch {
    Write-Error "Unable to download & extract tSQLt from '$DownloadUrl'. Ensure version is valid." -ErrorAction "Stop"
}

# Install
if ($IsLinux) {
    sqlcmd -S $SqlInstance -d $Database -q $CLRSecurityQuery
    sqlcmd -S $SqlInstance -d $Database -i $setupFile
    sqlcmd -S $SqlInstance -d $Database -i $installFile
}
elseif ($IsWindows) {
    $connSplat = @{
        ServerInstance = $SqlInstance
        Database = $Database
    }
    if (!(Get-SqlDatabase -ServerInstance $SqlInstance -Name $Database)) {
        Write-Error "Database '$Database' not found." -ErrorAction "Stop"
    }
    Invoke-SqlCmd @connSplat -Query $CLRSecurityQuery -OutputSqlErrors
    Invoke-SqlCmd @connSplat -InputFile $setupFile -OutputSqlErrors
    Invoke-SqlCmd @connSplat -InputFile $installFile -Verbose -OutputSqlErrors
}
else {
    Write-Error "Only Linux and Windows operation systems supported." -ErrorAction "Stop"
}
Write-Output "Installation completed."

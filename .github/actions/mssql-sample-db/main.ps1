param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("WideWorldImporters")]
    [string]$Database,
    [Parameter(Mandatory = $true)]
    [string]$SqlInstance
)

if ($Env:RUNNER_OS -ne "Windows") {
    Write-Error "This action only supported on Windows runners." -ErrorAction "Stop"
}

if ($Database -eq "WideWorldImporters") {
    $BackupPath = Join-Path -Path $Env:RUNNER_TEMP -ChildPath "$Database.bak"
    Write-Output "Downloading '$Database' to $BackupPath ..."
    $Uri = "https://github.com/Microsoft/sql-server-samples/releases/download/wide-world-importers-v1.0/WideWorldImporters-Full.bak"
    Invoke-WebRequest -Uri $Uri -OutFile $BackupPath
    Write-Output "Restoring '$Database' database ..."
    $null = Restore-DbaDatabase -SqlInstance $SqlInstance -DatabaseName $Database -Path $BackupPath -WithReplace -EnableException
    Get-DbaDatabase -SqlInstance $SqlInstance -Database $Database
}
else {
    Write-Output "$Database not supported yet - try opening a PR!"
}

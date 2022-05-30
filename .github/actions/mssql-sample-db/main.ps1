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

Write-Output "Thanks for using $Env:GITHUB_ACTION!"

if ($Database -eq "WideWorldImporters") {
    $BackupPath = Join-Path -Path $Env:RUNNER_TEMP -ChildPath "$Database.bak"
    $Uri = "https://github.com/Microsoft/sql-server-samples/releases/download/wide-world-importers-v1.0/WideWorldImporters-Full.bak"
    $Documentation = "https://docs.microsoft.com/en-us/sql/samples/wide-world-importers-what-is"
}

Write-Output "Documentation: $Documentation"
Write-Output ""

Write-Output "Downloading '$Database' to $BackupPath ..."
Invoke-WebRequest -Uri $Uri -OutFile $BackupPath
Write-Output "Restoring '$Database' database ..."
$null = Restore-DbaDatabase -SqlInstance $SqlInstance -DatabaseName $Database -Path $BackupPath -WithReplace -EnableException
Get-DbaDatabase -SqlInstance $SqlInstance -Database $Database | Select-Object -Property Name, Status, SizeMB, SqlInstance

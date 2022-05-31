param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("WideWorldImporters")]
    [string]$Database,
    [Parameter(Mandatory = $true)]
    [string]$SqlInstance
)

if ($Database -eq "WideWorldImporters") {
    $BackupFile = "$Database.bak"
    $BackupPath = Join-Path -Path $Env:RUNNER_TEMP -ChildPath $BackupFile
    $Uri = "https://github.com/Microsoft/sql-server-samples/releases/download/wide-world-importers-v1.0/WideWorldImporters-Full.bak"
    $Documentation = "https://docs.microsoft.com/en-us/sql/samples/wide-world-importers-what-is"
}

Write-Output "Thanks for using MSSQL Sample Database!"
Write-Output "📃: $Documentation"
Write-Output "-----"

if ($Env:RUNNER_OS -eq "Linux") {
    docker exec -it restore-db mkdir /var/opt/mssql/backup
    curl -OutFile $BackupFile $Uri
    docker cp $BackupFile restore-db:/var/opt/mssql/backup
    docker exec -it restore-db /opt/mssql-tools/bin/sqlcmd `
        -S localhost -U SA -P $Env:SA_PASSWORD `
        -Q "RESTORE DATABASE WideWorldImporters FROM DISK = '/var/opt/mssql/backup/$BackupFile' WITH MOVE 'WWI_Primary' TO '/var/opt/mssql/data/WideWorldImporters.mdf', MOVE 'WWI_UserData' TO '/var/opt/mssql/data/WideWorldImporters_userdata.ndf', MOVE 'WWI_Log' TO '/var/opt/mssql/data/WideWorldImporters.ldf', MOVE 'WWI_InMemory_Data_1' TO '/var/opt/mssql/data/WideWorldImporters_InMemory_Data_1'"
    docker exec -it restore-db /opt/mssql-tools/bin/sqlcmd `
        -S localhost -U SA -P $Env:SA_PASSWORD `
        -Q "SELECT Name FROM sys.Databases"

}
elseif ($Env:RUNNER_OS -eq "Windows") {
    Write-Output "Downloading '$Database' to '$BackupPath' ..."
    Invoke-WebRequest -Uri $Uri -OutFile $BackupPath
    Write-Output "Restoring '$Database' ..."
    $null = Restore-DbaDatabase -SqlInstance $SqlInstance -DatabaseName $Database -Path $BackupPath -WithReplace -EnableException
    Get-DbaDatabase -SqlInstance $SqlInstance -Database $Database | Select-Object -Property Name, Status, SizeMB, SqlInstance
}

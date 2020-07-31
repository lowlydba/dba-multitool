Write-Host "Starting SQL Server"

$SQLInstance = $env:MSSQL;
Start-Service "MSSQL`$$SQLInstance";
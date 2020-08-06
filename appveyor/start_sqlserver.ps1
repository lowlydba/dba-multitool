$Color = "Green"

Write-Host "Starting SQL Server" -ForegroundColor $Color

$SQLInstance = $env:MSSQL;
Start-Service "MSSQL`$$SQLInstance";
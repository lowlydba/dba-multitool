$File = "install_dba-multitool.sql"
$Filter = "sp_*.sql"

if (Test-Path $File) {
    Remove-Item $File
}

Get-Item $Filter | Get-Content | Out-File $File -Encoding utf8
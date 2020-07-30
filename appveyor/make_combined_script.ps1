$File = "install_expsql.sql"

if (Test-Path $File) {
    Remove-Item $File
}

Get-Item sp_*.sql | Get-Content | Out-File $File
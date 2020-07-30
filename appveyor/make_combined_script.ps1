$File = "install_expsql.sql"

Get-Item sp_*.sql | Get-Content | Out-File $File
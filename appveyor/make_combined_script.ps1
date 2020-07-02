$File = "install_expsql.sql"

Set-Location ../
Get-Item *.sql | Get-Content | Out-File $File
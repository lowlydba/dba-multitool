# Install code coverage tool
If (!(Get-Package -Name GOEddie.SQLCover)) {
    Install-Package GOEddie.SQLCover -Force | Out-Null
}
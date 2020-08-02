$LocalTest = $true
$SqlInstance = "localhost"
$Database = "tSQLt"
$TrustedConnection = "yes"
$TestPath = "tests\run"
$TestBuildPath = "tests\build"

# Install TSQLLint
npm install tsqllint -g

# Install latest versions
Write-Host "Installing scripts..."
ForEach ($filename in Get-Childitem -Filter "*.sql") {
    Invoke-SqlCmd -ServerInstance $SqlInstance -Database $Database -InputFile $filename.fullname -Verbose | Out-Null
}

# Lint code 
Write-Host "Linting scripts..."
tsqllint *.sql

# Install tests
Write-Host "Installing tSQLt Tests..."
ForEach ($filename in Get-Childitem -Path $TestBuildPath -Filter "*.sql") {
    Invoke-SqlCmd -ServerInstance $SqlInstance -Database $Database -InputFile $filename.fullname -Verbose | Out-Null
}

# Run tests
. .\appveyor\sqlcover\Run_SQLCover.ps1 -LocalTest $LocalTest -SqlInstance $SqlInstance -Database $Database -TrustedConnection $TrustedConnection -TestPath $TestPath
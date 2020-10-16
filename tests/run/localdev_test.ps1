param( 
    [Parameter()] 
    $SqlInstance = "localhost",
    $Database = "tSQLt"
    )

$LocalTest = $true
$TrustedConnection = "yes"
$TestBuildPath = "tests\build"
$Color = "Green"
$LintConfig = ".\appveyor\tsqllint\.tsqllintrc_150"

# Install depndencies
.\appveyor\install_dependencies.ps1 -Color $Color

# Install latest versions
.\appveyor\generate_combined_script.ps1
.\appveyor\install_tool.ps1 -SqlInstance $SqlInstance -Database $Database -Color $Color

# Lint code 
.\appveyor\run_tsqllint.ps1 -Config $LintConfig -Color $Color

# Install tSQLt tests
.\appveyor\build_tsqlt_tests.ps1 -SqlInstance $SqlInstance -Database $Database -TestPath $TestBuildPath -Color $Color

# Run tests
.\appveyor\sqlcover\Run_SQLCover.ps1 -LocalTest $LocalTest -SqlInstance $SqlInstance -Database $Database -TrustedConnection $TrustedConnection -Color $Color
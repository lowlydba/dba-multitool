. "$PSScriptRoot\constants.ps1"

$TestBuildPath = "tests\build"
$Color = "Green"
$LintConfig = ".\appveyor\tsqllint\.tsqllintrc_150"

# Install depndencies
.\appveyor\install_dependencies.ps1 -Color $Color

# Install latest versions
.\appveyor\generate_combined_script.ps1
.\appveyor\install_tool.ps1 -SqlInstance $SqlInstance -Database $Database -Color $Color

# Install tSQLt tests
.\appveyor\build_tsqlt_tests.ps1 -SqlInstance $SqlInstance -Database $Database -TestPath $TestBuildPath -Color $Color

# Run tests
.\appveyor\run_pester_tests.ps1 -SqlInstance $SqlInstance -Database $Database -LocalTest -Color $Color -CodeCoverage
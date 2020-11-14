. "$PSScriptRoot\constants.ps1"

# Install depndencies
.\appveyor\install_dependencies.ps1 -Color $Color

# Install code coverage dependencies
.\appveyor\install_coverage_dependencies.ps1 -Color $Color

# Run tests
.\appveyor\run_pester_tests.ps1 -SqlInstance $SqlInstance -Database $Database -LocalTest -Color $Color -CodeCoverage
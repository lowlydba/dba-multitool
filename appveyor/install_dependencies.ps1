param( 
    [Parameter()] 
    $Color = "Green"
)

Write-Host "Installing dependencies..." -ForegroundColor $Color

# TSQLLinter
$result = npm list -g --depth=0
If (-Not ($result -Match "tsqllint")) {
    npm install tsqllint -g | Out-Null 
}

# DbaTools
if (!(Get-Module -ListAvailable -Name DbaTools)) {
    Install-Module DbaTools -Force -AllowClobber
}

# Pester
if (!(Get-InstalledModule -Name Pester -MinimumVersion 4.0.0)) {
    Install-Module Pester -Force -AllowClobber -WarningAction SilentlyContinue
}
param( 
    [Parameter()] 
    $Color = "Green"
)

Write-Host "Installing dependencies..." -ForegroundColor $Color

# TSQLLinter - run as job to suck up nasty output
$result = npm list -g --depth=0
If (-Not ($result -Match "tsqllint")) {
    Start-Job -ScriptBlock { npm install tsqllint -g } | Out-Null
}

# DbaTools
if (!(Get-Module -ListAvailable -Name DbaTools)) {
    Install-Module DbaTools -Force -AllowClobber
}

# Pester
if (!(Get-InstalledModule -Name Pester -MinimumVersion 4.0.0 -ErrorAction SilentlyContinue)) {
    Install-Module Pester -Force -AllowClobber -WarningAction SilentlyContinue -SkipPublisherCheck
    Remove-Module Pester -Force
    Import-Module Pester -MinimumVersion 4.0.0
}

if (!(Get-Module -Name Pester | Where-Object { $PSItem.Version -lt 4.0.0 })) {
    Remove-Module Pester -Force -ErrorAction SilentlyContinue
    Import-Module Pester -MinimumVersion 4.0.0
}
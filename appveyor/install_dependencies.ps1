param( 
    [Parameter()] 
    $Color = "Green"
)

Write-Host "Installing dependencies..." -ForegroundColor $Color

# TSQLLinter - run async since its a bit slow
$result = npm list -g --depth=0
If (-Not ($result -Match "tsqllint")) {
    $TSQLLintJob = Start-Job -ScriptBlock { npm install tsqllint -g }
}

# DbaTools
if (!(Get-Module -ListAvailable -Name DbaTools)) {
    $DbaToolsJob = Start-Job -ScriptBlock { Install-Module DbaTools -Force -AllowClobber -SkipPublisherCheck }
}

# Pester
if (!(Get-InstalledModule -Name Pester -MinimumVersion 4.0.0 -ErrorAction SilentlyContinue)) {
    Install-Module Pester -Force -AllowClobber -WarningAction SilentlyContinue -SkipPublisherCheck -MinimumVersion 4.0.0
}

if (!(Get-Module -Name Pester | Where-Object { $PSItem.Version -lt 4.0.0 })) {
    if (Get-Module -Name Pester) {
        Remove-Module Pester -Force
    }
    Import-Module Pester -MinimumVersion 4.0.0
}

# Wait for Jobs before proceeding
If ($TSQLLintJob) {
    Wait-Job $TSQLLintJob.Id | Out-Null
}
If ($DbaToolsJob) {
    Wait-Job $DbaToolsJob.Id | Out-Null
}
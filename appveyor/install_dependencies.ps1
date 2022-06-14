#PSScriptAnalyzer rule excludes
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '')]

param(
    $Color = "Green"
)

Write-Host "Installing dependencies..." -ForegroundColor $Color

# DbaTools
if (!(Get-Module -ListAvailable -Name DbaTools)) {
    $DbaToolsJob = Start-Job -ScriptBlock { Install-Module DbaTools -Force -AllowClobber }
}

# Pester
if (!(Get-InstalledModule -Name Pester -MaximumVersion 5.1.9 -ErrorAction SilentlyContinue)) {
    Install-Module Pester -Force -AllowClobber -WarningAction SilentlyContinue -SkipPublisherCheck -MaximumVersion 5.1.9
}

if (!(Get-Module -Name Pester | Where-Object { $PSItem.Version -lt 5.1.0 })) {
    if (Get-Module -Name Pester) {
        Remove-Module Pester -Force
    }
    Import-Module Pester -MaximumVersion 5.1.9 -Force
}

If ($DbaToolsJob) {
    Wait-Job $DbaToolsJob.Id | Out-Null
}

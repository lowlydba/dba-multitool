#PSScriptAnalyzer rule excludes
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '')]

param(
    [Parameter()]
    [switch]$CodeCoverageOnly,
    $Color = "Green"
)


if ($CodeCoverageOnly.IsPresent) {
    Write-Host "Installing code coverage tool..." -ForegroundColor $Color

    # GoEddie SQLCover
    If (!(Get-Package -Name GOEddie.SQLCover -ErrorAction SilentlyContinue)) {
        Install-Package GOEddie.SQLCover -Force | Out-Null
    }

    # Install codecov tracker
    choco install codecov --no-progress --limit-output | Out-Null
}

else {
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
}
param( 
    [Parameter()] 
    $Color = "Green"
    )

Write-Host "Installing dependencies..." -ForegroundColor $Color

# TSQLLinter
# Try/Catch to stop appveyor unnecessary errors
Try { npm install tsqllint -g | Out-Null }
Catch { }


# SQLServer Module
if (!(Get-Module -ListAvailable -Name SqlServer)) {
    Install-Module SqlServer -Force -AllowClobber
}

# DbaTools Module
Install-Module DbaTools -Force -AllowClobber
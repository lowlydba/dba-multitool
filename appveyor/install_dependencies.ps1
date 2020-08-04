param( 
    [Parameter()] 
    $Color = "Green"
    )

Write-Host "Installing dependencies..." -ForegroundColor $Color

# TSQLLinter
npm install tsqllint -g

# SQLServer Module
if (!(Get-Module -ListAvailable -Name SqlServer)) {
    Install-Module SqlServer -Force -AllowClobber
}
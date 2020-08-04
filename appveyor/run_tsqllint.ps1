param( 
    [Parameter()] 
    $Config = $env:LINT_CONFIG,
    $Color = "Green"
    )

Write-Host "Running TSQLLint with config $Config..." -ForegroundColor $Color
tsqllint -c $Config *.sql
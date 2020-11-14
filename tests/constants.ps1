
$script:IsAzureSQL = [System.Convert]::ToBoolean($env:AzureSQL)
$Pass = $env:AZURE_SQL_PASS
$User = $env:AZURE_SQL_USER

# Fill in local values if not running in appveyor
$SqlInstance = If (!$env:DB_INSTANCE) { "localhost" } Else { $env:DB_INSTANCE }
$Database = If (!$env:TARGET_DB) { "tsqlt" } Else { $env:TARGET_DB }
$TSQLLintConfig = If (!$env:LINT_CONFIG) { "appveyor\tsqllint\.tsqllintrc_150" } Else { $env:LINT_CONFIG }

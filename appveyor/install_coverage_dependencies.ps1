# Install code coverage tool
Install-Package GOEddie.SQLCover -Force | Out-Null

# Install codecov.io uploader
choco install codecov --no-progress --limit-output | Out-Null
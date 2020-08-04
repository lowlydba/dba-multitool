git config --global credential.helper store
Add-Content "$HOME\.git-credentials" "https://$($env:access_token):x-oauth-basic@github.com`n" -NoNewLine
git config --global user.email "appveyor@lowlydba.com"
git config --global user.name "Appveyor"
git config --global core.safecrlf false
git clone -q --single-branch --branch=%APPVEYOR_PULL_REQUEST_HEAD_REPO_BRANCH% https://github.com/LowlyDBA/ExpressSQL.git %APPVEYOR_BUILD_FOLDER%
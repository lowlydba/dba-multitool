# Exit build with success if commit is just files generated from CI
If ($env:APPVEYOR_REPO_COMMIT_MESSAGE -eq $env:CI_COMMIT_MSG) {
    Write-Output "Commit is CI produced files only. Skipping build."
    Exit-AppveyorBuild
}
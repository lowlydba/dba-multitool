# Exit build with success if commit is just files generated from CI
If (%APPVEYOR_REPO_COMMIT_MESSAGE% -eq "CI produced files") {
    Write-Output "Commit is CI produced files only. Skipping build."
    Exit-Appveyor
}
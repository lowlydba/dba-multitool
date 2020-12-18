# Stage files
git add .

# Check if any files were actually staged
$StagedFiles = git diff --staged

# Commit & push if stated
If ($StagedFiles) {
    git commit -a -m $env:CI_COMMIT_MSG -q
    git push origin $env:APPVEYOR_PULL_REQUEST_HEAD_REPO_BRANCH -f -q
}
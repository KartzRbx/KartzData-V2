# Creates the public GitHub repository KartzRbx/DataServiceV2 and pushes the current branch.
# Prerequisites:
#   1. GitHub CLI installed
#   2. Run: gh auth login

$ErrorActionPreference = "Stop"

$repoOwner = "KartzRbx"
$repoName = "DataServiceV2"
$description = "High-performance Roblox data service with typed paths, QuickNet replication, and ProfileStore persistence"

gh auth status | Out-Null

$existing = gh repo view "$repoOwner/$repoName" 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host "Repository $repoOwner/$repoName already exists."
} else {
    gh repo create "$repoOwner/$repoName" `
        --public `
        --description $description `
        --disable-wiki `
        --disable-issues=false
    Write-Host "Created https://github.com/$repoOwner/$repoName"
}

$remoteName = "dataservicev2"
$remoteUrl = "https://github.com/$repoOwner/$repoName.git"

if (git remote get-url $remoteName 2>$null) {
    git remote set-url $remoteName $remoteUrl
} else {
    git remote add $remoteName $remoteUrl
}

$branch = git branch --show-current
if (-not $branch) {
    throw "No current git branch found."
}

Write-Host ""
Write-Host "Remote '$remoteName' -> $remoteUrl"
Write-Host "Push with:"
Write-Host "  git push -u $remoteName $branch"
Write-Host ""
Write-Host "If you have uncommitted changes, commit first:"
Write-Host "  git add ."
Write-Host "  git commit -m `"feat: DataServiceV2 package source`""

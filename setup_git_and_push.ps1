# setup_git_and_push.ps1
# Usage: edit $GitHubUser and $RepoName at top OR run interactively when prompted.
# This configures git user.name/email, initializes repo (if needed), and pushes to GitHub.

# ---------- USER CONFIG (edit if you want) ----------
$GlobalGitUserName = "Bella Assistant"         # human-friendly name used for commits
$GlobalGitUserEmail = "bellamyassist@gmail.com" # your provided bella email
# If you want to auto-fill GitHub repo details below, set them. Otherwise you'll be prompted.
$GitHubUser = ""    # set YOUR_GITHUB_USERNAME here if you want
$RepoName   = ""    # set repo name (e.g., bella-ai) if you want
# ---------------------------------------------------

Set-Location -Path "C:\bella"

Write-Host "Configuring global git user.name and user.email..."
git --version > $null 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Error "git not found in PATH. Install Git and re-run this script. https://git-scm.com/downloads"
    exit 1
}

git config --global user.name "$GlobalGitUserName"
git config --global user.email "$GlobalGitUserEmail"
Write-Host "git global user.name -> $(git config --global user.name)"
Write-Host "git global user.email -> $(git config --global user.email)"

# If no remote info provided, ask
if ([string]::IsNullOrWhiteSpace($GitHubUser)) {
    $GitHubUser = Read-Host "Enter your GitHub username (e.g. sameer123) or press Enter to cancel"
    if ([string]::IsNullOrWhiteSpace($GitHubUser)) { Write-Host "Cancelled."; exit 0 }
}
if ([string]::IsNullOrWhiteSpace($RepoName)) {
    $RepoName = Read-Host "Enter your GitHub repository name (e.g. bella-ai). Create the repo on GitHub first"
    if ([string]::IsNullOrWhiteSpace($RepoName)) { Write-Host "Cancelled."; exit 0 }
}

$remoteUrl = "https://github.com/$GitHubUser/$RepoName.git"

# Initialize repo if needed
if (-not (Test-Path ".git")) {
    Write-Host "Initializing git repo at C:\bella..."
    git init
} else {
    Write-Host "Git repo already initialized."
}

# Add remote if missing or update it
$existingRemote = git remote -v 2>$null | Select-String "origin" -Quiet
if (-not $existingRemote) {
    git remote add origin $remoteUrl
    Write-Host "Added remote origin -> $remoteUrl"
} else {
    Write-Host "Origin remote exists. Setting URL to $remoteUrl"
    git remote set-url origin $remoteUrl
}

# Ensure main branch exists and is checked out
try {
    git rev-parse --verify main > $null 2>&1
    git checkout main 2>$null
} catch {
    git checkout -b main
}

Write-Host "Staging and committing files..."
git add -A
# Only commit if changes exist
$status = git status --porcelain
if ([string]::IsNullOrWhiteSpace($status)) {
    Write-Host "No changes to commit."
} else {
    git commit -m "Initial commit: Bella ecosystem (auto)"
    Write-Host "Committed changes."
}

Write-Host "Pushing to GitHub: $remoteUrl"
# A prompt will appear to supply username/password/AUTH; better: use GitHub CLI, credential manager or PAT stored in credential manager
git push -u origin main

if ($LASTEXITCODE -eq 0) {
    Write-Host "Push succeeded. Open: https://github.com/$GitHubUser/$RepoName"
} else {
    Write-Warning "Push failed. If you use 2FA you need to use a Personal Access Token (PAT) or GitHub CLI auth. See README or run 'gh auth login'."
}

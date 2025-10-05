<#
Attempt to install Fusion into C:\Fusion.
If FUSION_REPO_URL is set in C:\bella\.env it will try to git clone.
Otherwise creates placeholder folder and README.
Logs: C:\bella\logs\install_fusion.log
#>

$ErrorActionPreference = 'Stop'
$Root = "C:\bella"
$Logs = Join-Path $Root "logs"
if (-not (Test-Path $Logs)) { New-Item -ItemType Directory -Path $Logs -Force | Out-Null }
$Log = Join-Path $Logs "install_fusion.log"
"$(Get-Date -Format u) | start install_fusion" | Out-File -FilePath $Log -Encoding utf8 -Append

function L { param($m) "$(Get-Date -Format u) | $m" | Out-File -FilePath $Log -Append -Encoding utf8; Write-Host $m }

# read .env for FUSION_REPO_URL
$envFile = Join-Path $Root ".env"
$fusionUrl = $null
if (Test-Path $envFile) {
    Get-Content $envFile | ForEach-Object {
        if ($_ -match '^FUSION_REPO_URL\s*=\s*(.+)$') { $fusionUrl = $Matches[1].Trim() }
    }
}

$target = "C:\Fusion"
if (Test-Path $target) {
    L "Target $target already exists. Will skip clone but check for requirements."
} else {
    if ($fusionUrl -and $fusionUrl.Trim() -ne "") {
        L "Cloning Fusion from $fusionUrl -> $target"
        # ensure git exists
        try {
            & git --version 2>&1 | Out-File -FilePath $Log -Append -Encoding utf8
            git clone $fusionUrl $target 2>&1 | Out-File -FilePath $Log -Append -Encoding utf8
            L "git clone finished"
        } catch {
            L "ERROR: git clone failed: $_"
            exit 4
        }
    } else {
        L "No FUSION_REPO_URL provided. Creating placeholder at $target"
        New-Item -ItemType Directory -Path $target -Force | Out-Null
        $readme = Join-Path $target "README.md"
        @"
# Fusion placeholder
No FUSION_REPO_URL set in C:\bella\.env
Set FUSION_REPO_URL to a git repo and re-run install_fusion.ps1 to clone real code.
"@ | Out-File -FilePath $readme -Encoding utf8
        L "Placeholder created"
    }
}

# If requirements.txt exists in repo, install them into venv
$venvPy = Join-Path $Root "venv\Scripts\python.exe"
$reqsPath = Join-Path $target "requirements.txt"
if (Test-Path $reqsPath -and Test-Path $venvPy) {
    L "Installing Fusion requirements from $reqsPath"
    & $venvPy -m pip install -r $reqsPath 2>&1 | Out-File -FilePath $Log -Append -Encoding utf8
    L "Fusion requirements installed"
}

L "install_fusion finished"
exit 0

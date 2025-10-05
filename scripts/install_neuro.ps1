<#
Attempt to install Neuro into C:\Neuroloop.
If NEURO_REPO_URL is set in C:\bella\.env it will try to git clone.
Otherwise creates placeholder folder and README.
Logs: C:\bella\logs\install_neuro.log
#>

$ErrorActionPreference = 'Stop'
$Root = "C:\bella"
$Logs = Join-Path $Root "logs"
if (-not (Test-Path $Logs)) { New-Item -ItemType Directory -Path $Logs -Force | Out-Null }
$Log = Join-Path $Logs "install_neuro.log"
"$(Get-Date -Format u) | start install_neuro" | Out-File -FilePath $Log -Encoding utf8 -Append

function L { param($m) "$(Get-Date -Format u) | $m" | Out-File -FilePath $Log -Append -Encoding utf8; Write-Host $m }

# read .env for NEURO_REPO_URL
$envFile = Join-Path $Root ".env"
$neuroUrl = $null
if (Test-Path $envFile) {
    Get-Content $envFile | ForEach-Object {
        if ($_ -match '^NEURO_REPO_URL\s*=\s*(.+)$') { $neuroUrl = $Matches[1].Trim() }
    }
}

$target = "C:\Neuroloop"
if (Test-Path $target) {
    L "Target $target already exists. Will skip clone but check for requirements."
} else {
    if ($neuroUrl -and $neuroUrl.Trim() -ne "") {
        L "Cloning Neuro from $neuroUrl -> $target"
        # ensure git exists
        try {
            & git --version 2>&1 | Out-File -FilePath $Log -Append -Encoding utf8
            git clone $neuroUrl $target 2>&1 | Out-File -FilePath $Log -Append -Encoding utf8
            L "git clone finished"
        } catch {
            L "ERROR: git clone failed: $_"
            exit 4
        }
    } else {
        L "No NEURO_REPO_URL provided. Creating placeholder at $target"
        New-Item -ItemType Directory -Path $target -Force | Out-Null
        $readme = Join-Path $target "README.md"
        @"
# Neuro placeholder
No NEURO_REPO_URL set in C:\bella\.env
Set NEURO_REPO_URL to a git repo and re-run install_neuro.ps1 to clone real code.
"@ | Out-File -FilePath $readme -Encoding utf8
        L "Placeholder created"
    }
}

# If requirements.txt exists in repo, install them into venv
$venvPy = Join-Path $Root "venv\Scripts\python.exe"
$reqsPath = Join-Path $target "requirements.txt"
if (Test-Path $reqsPath -and Test-Path $venvPy) {
    L "Installing Neuro requirements from $reqsPath"
    & $venvPy -m pip install -r $reqsPath 2>&1 | Out-File -FilePath $Log -Append -Encoding utf8
    L "Neuro requirements installed"
}

L "install_neuro finished"
exit 0

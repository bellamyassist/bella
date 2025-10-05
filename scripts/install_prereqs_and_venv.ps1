<#
Creates or reuses a virtualenv at C:\bella\venv and installs required python packages.
Saves logs to C:\bella\logs/install_prereqs_and_venv.log
#>
$ErrorActionPreference = 'Stop'
$Root = "C:\bella"
$Logs = Join-Path $Root "logs"
if (-not (Test-Path $Logs)) { New-Item -ItemType Directory -Path $Logs -Force | Out-Null }
$Log = Join-Path $Logs "install_prereqs_and_venv.log"
"$(Get-Date -Format u) | start prereqs" | Out-File -FilePath $Log -Encoding utf8 -Append

function L { param($m) "$(Get-Date -Format u) | $m" | Out-File -FilePath $Log -Append -Encoding utf8; Write-Host $m }

# 1) Ensure python is available
try {
    $py = & python -V 2>&1
    L "Python found: $py"
} catch {
    L "ERROR: Python not found in PATH. Please install Python 3.10+ and re-run."
    exit 2
}

# 2) Create venv if missing
$venv = Join-Path $Root "venv"
if (-not (Test-Path $venv)) {
    L "Creating venv at $venv"
    python -m venv $venv 2>&1 | Out-File -FilePath $Log -Append -Encoding utf8
    L "venv created"
} else {
    L "venv already exists at $venv"
}

# 3) Activate and install packages into venv via pip
$venvPython = Join-Path $venv "Scripts\python.exe"
if (-not (Test-Path $venvPython)) {
    L "venv python not found at $venvPython"
    exit 3
}

# Upgrade pip
L "Upgrading pip"
& $venvPython -m pip install --upgrade pip setuptools wheel 2>&1 | Out-File -FilePath $Log -Append -Encoding utf8

# Install required packages
$reqs = @(
    "fastapi",
    "uvicorn[standard]",
    "python-dotenv",
    "deep-translator",
    "requests"
)
L "Installing python packages: $($reqs -join ', ')"
& $venvPython -m pip install $reqs 2>&1 | Out-File -FilePath $Log -Append -Encoding utf8

L "prereqs done"
exit 0

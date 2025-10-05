<#
install_prereqs.ps1
Checks for and tries to install common prerequisites:
 - Git, Python3, pip, unzip (7zip), Chrome (optional)
 - Creates or uses existing venv at C:\bella\venv
Logs to C:\bella\logs\install_prereqs.log
#>

$ErrorActionPreference = "Stop"
$Root = "C:\bella"
$LogDir = Join-Path $Root "logs"
New-Item -Path $LogDir -ItemType Directory -Force | Out-Null
$LogFile = Join-Path $LogDir "install_prereqs.log"

function Log {
    param($m)
    $t = (Get-Date).ToString("s")
    "$t | $m" | Out-File -FilePath $LogFile -Encoding utf8 -Append
    Write-Host $m
}

function CommandExists {
    param($cmd)
    try {
        $null = Get-Command $cmd -ErrorAction Stop
        return $true
    } catch {
        return $false
    }
}

Log "START install_prereqs"

# 1) Git
if (-not (CommandExists git)) {
    Log "git not found"
    # try winget / choco / manual message
    if (CommandExists winget) {
        Log "Installing git via winget..."
        winget install --id Git.Git -e --silent | Out-File -FilePath $LogFile -Append -Encoding utf8
    } else {
        Log "Please install Git manually and rerun this script (https://git-scm.com/download/win)"
        Write-Host "Install git manually: https://git-scm.com/download/win" -ForegroundColor Yellow
    }
} else { Log "git found" }

# 2) Python
if (-not (CommandExists python)) {
    Log "python not found"
    if (CommandExists winget) {
        Log "Installing python via winget..."
        winget install --id Python.Python.3 -e --silent | Out-File -FilePath $LogFile -Append -Encoding utf8
    } else {
        Log "Please install Python 3.10+ manually and ensure python is on PATH"
        Write-Host "Install Python: https://www.python.org/downloads/windows/" -ForegroundColor Yellow
    }
} else { 
    $pyv = (python --version 2>&1)
    Log "python found: $pyv"
}

# 3) Ensure pip / venv
try {
    python -m pip --version | Out-Null
    Log "pip available"
} catch {
    Log "pip not available - trying ensurepip"
    try {
        python -m ensurepip --upgrade | Out-File -FilePath $LogFile -Append -Encoding utf8
        python -m pip install --upgrade pip | Out-File -FilePath $LogFile -Append -Encoding utf8
        Log "pip installed/updated"
    } catch {
        Log "Failed to ensure pip - please install pip manually"
    }
}

# 4) Create venv if missing
$VenvPath = Join-Path $Root "venv"
if (-not (Test-Path (Join-Path $VenvPath "Scripts\python.exe"))) {
    Log "Creating venv at $VenvPath"
    python -m venv $VenvPath 2>&1 | Out-File -FilePath $LogFile -Append -Encoding utf8
    & "$VenvPath\Scripts\python.exe" -m pip install --upgrade pip setuptools wheel | Out-File -FilePath $LogFile -Append -Encoding utf8
} else {
    Log "Using existing venv at $VenvPath"
}

# 5) 7zip/unzip fallback for zip downloads
if (-not (CommandExists 7z) -and -not (CommandExists tar)) {
    Log "7zip not found; please install 7zip if you expect zip downloads."
}

Log "END install_prereqs"

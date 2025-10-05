# self_heal.ps1 — lightweight repair script for common failures
Param(
    [switch]$DoFixes = $true
)

$Root = "C:\bella"
$Logs = Join-Path $Root "logs"
$Outbox = Join-Path $Root "outbox"
if (-not (Test-Path $Logs)) { New-Item -ItemType Directory -Path $Logs -Force | Out-Null }
if (-not (Test-Path $Outbox)) { New-Item -ItemType Directory -Path $Outbox -Force | Out-Null }
$logfile = Join-Path $Logs "self_heal.log"
Function L($m) { "$(Get-Date -Format u) | $m" | Out-File -FilePath $logfile -Append -Encoding utf8; Write-Host $m }

L "Starting self_heal (DoFixes=$DoFixes)"

# 1) venv existence
$venvPython = Join-Path $Root "venv\Scripts\python.exe"
if (-not (Test-Path $venvPython)) {
    L "VENV missing at $venvPython"
    if ($DoFixes) {
        try {
            L "Creating venv..."
            python -m venv "$Root\venv" 2>&1 | Out-File -FilePath $logfile -Append -Encoding utf8
            & "$Root\venv\Scripts\python.exe" -m pip install --upgrade pip setuptools wheel 2>&1 | Out-File -FilePath $logfile -Append -Encoding utf8
            L "venv created"
        } catch {
            L "Failed to create venv: $_"
        }
    }
} else {
    L "venv ok"
}

# 2) required python packages present? try to install minimal ones into venv
$venvPy = Join-Path $Root "venv\Scripts\python.exe"
if (Test-Path $venvPy) {
    try {
        L "Checking pip packages"
        & $venvPy -m pip install --upgrade pip 2>&1 | Out-File -FilePath $logfile -Append -Encoding utf8
        $needed = @("fastapi","uvicorn[standard]","python-dotenv","requests","deep-translator")
        foreach ($p in $needed) {
            & $venvPy -m pip show $p > $null 2>&1
            if ($LASTEXITCODE -ne 0) {
                L "Package missing: $p"
                if ($DoFixes) {
                    L "Installing $p..."
                    & $venvPy -m pip install $p 2>&1 | Out-File -FilePath $logfile -Append -Encoding utf8
                }
            } else {
                L "Found $p"
            }
        }
    } catch {
        L "Error when installing/checking packages: $_"
    }
} else {
    L "venv python still not found"
}

# 3) is uvicorn server running? try to start if not
$port=8000
$listening = netstat -a -n -o | findstr ":$port" | Select-String ":$port"
if ($listening) {
    L "Port $port seems in use (server probably running)."
} else {
    L "Port $port not in use. Will attempt to start Bella server (non-blocking)."
    if ($DoFixes) {
        $startbat = Join-Path $Root "start_bella.bat"
        if (Test-Path $startbat) {
            Start-Process -FilePath $startbat -WindowStyle Minimized
            L "Called start_bella.bat"
        } else {
            # fallback: start via venv python -m uvicorn
            $app = "bella_core.app:app"
            if (Test-Path $venvPy) {
                Start-Process -FilePath $venvPy -ArgumentList "-m","uvicorn",$app,"--reload","--host","127.0.0.1","--port","8000" -WindowStyle Minimized
                L "Started uvicorn via venv python"
            } else {
                L "Cannot start uvicorn: venv python not found"
            }
        }
    }
}

# 4) check for missing git tool (if needed for clone)
try {
    git --version > $null 2>&1
    if ($LASTEXITCODE -eq 0) { L "git present" } else { throw "no git" }
} catch {
    L "git not found"
    if ($DoFixes) {
        L "Attempting to install git via winget (if available)"
        try {
            winget install --id Git.Git -e --source winget 2>&1 | Out-File -FilePath $logfile -Append -Encoding utf8
            L "winget attempted git install (check log)"
        } catch {
            L "winget not available or install failed. Please install git manually."
        }
    }
}

L "self_heal finished. If problems remain, create logs bundle and paste path to me."

# create bundle helper
$ts = Get-Date -Format "yyyyMMdd_HHmmss"
$zip = Join-Path $Outbox "self_heal_logs_$ts.zip"
try {
    Compress-Archive -Path (Join-Path $Logs "*") -DestinationPath $zip -Force
    L "Logs zipped to $zip"
} catch {
    L "Failed to zip logs: $_"
}

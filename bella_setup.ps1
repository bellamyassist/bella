<#
bella_setup.ps1
Windows installer for Bella assistant (starter).
Run from PowerShell: .\bella_setup.ps1
#>

param(
    [string]$Root = "$env:USERPROFILE\bella"
)

Write-Host "=== Bella setup starting ==="
Write-Host "Root folder: $Root"

# Create directories
New-Item -ItemType Directory -Path $Root -Force | Out-Null
Set-Location -Path $Root

# Create required subfolders
$dirs = @("bella_core","services\fusion","services\neuro","patches","backups","logs","docs","ui")
foreach ($d in $dirs) {
    $full = Join-Path $Root $d
    if (-not (Test-Path $full)) { New-Item -ItemType Directory -Path $full | Out-Null }
}

# Create virtualenv
Write-Host "Creating Python virtual environment..."
python -m venv venv

# Activate venv for this script session
$activateScript = Join-Path $Root "venv\Scripts\Activate.ps1"
if (Test-Path $activateScript) {
    Write-Host "Activating venv..."
    & $activateScript
} else {
    Write-Warning "Could not find Activate.ps1. Please activate venv later: `venv\Scripts\Activate.ps1`"
}

# Create requirements.txt
$reqPath = Join-Path $Root "bella_core\requirements.txt"
@"
fastapi
uvicorn[standard]
gitpython
watchdog
python-dotenv
pydantic
pytest
black
ruff
mypy
requests
python-telegram-bot
docker
pyyaml
"@ | Out-File -FilePath $reqPath -Encoding utf8

# Create starter files (app.py, executor.py, utils.py)
$appPath = Join-Path $Root "bella_core\app.py"
$executorPath = Join-Path $Root "bella_core\executor.py"
$utilsPath = Join-Path $Root "bella_core\utils.py"

# app.py
@"
from fastapi import FastAPI
from pydantic import BaseModel
import os
from executor import Executor

app = FastAPI(title='Bella Core')
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
executor = Executor(root=ROOT)

class Cmd(BaseModel):
    cmd: str

@app.get('/health')
def health():
    return {'status':'ok','name':'Bella'}

@app.post('/run')
async def run_command(payload: Cmd):
    # run shell command through executor
    result = await executor.run_shell(payload.cmd)
    return result

# Basic playground endpoint
@app.get('/')
def index():
    return {'msg': 'Hello from Bella 🌸 — use /run to execute commands (safe ops only).'}
"@ | Out-File -FilePath $appPath -Encoding utf8

# executor.py (minimal)
@"
import asyncio
import subprocess
import os
from typing import Dict, Any

class Executor:
    def __init__(self, root: str):
        self.root = root

    async def run_shell(self, cmd: str) -> Dict[str, Any]:
        # Run a shell command asynchronously and capture output
        # NOTE: This runs on the machine - be careful with dangerous commands.
        proc = await asyncio.create_subprocess_shell(
            cmd,
            cwd=self.root,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE
        )
        stdout, stderr = await proc.communicate()
        return {
            'cmd': cmd,
            'returncode': proc.returncode,
            'stdout': stdout.decode('utf-8', errors='replace')[-10000:], # keep last chunk
            'stderr': stderr.decode('utf-8', errors='replace')[-10000:]
        }
"@ | Out-File -FilePath $executorPath -Encoding utf8

# utils.py
@"
import os, re

def guess_requirements(project_dir):
    pkgs = set()
    skip = {'os','sys','json','re','subprocess','typing','pathlib','asyncio','datetime'}
    for root,_,files in os.walk(project_dir):
        for f in files:
            if f.endswith('.py'):
                p = os.path.join(root,f)
                try:
                    txt = open(p,encoding='utf-8').read()
                except:
                    continue
                for m in re.findall(r'^\s*(?:from|import)\s+([a-zA-Z0-9_\.]+)', txt, flags=re.M):
                    top = m.split('.')[0]
                    if top and top not in skip:
                        pkgs.add(top)
    return sorted(pkgs)
"@ | Out-File -FilePath $utilsPath -Encoding utf8

# Minimal README
$readme = Join-Path $Root "README.md"
@"
Bella — starter assistant
========================

Place your services under 'services\\fusion' and 'services\\neuro'.
Activate venv: .\\venv\\Scripts\\Activate.ps1
Install dependencies: pip install -r bella_core\\requirements.txt
Start server: uvicorn bella_core.app:app --reload --host 0.0.0.0 --port 8000

Be careful: /run executes shell commands on your machine.
"@ | Out-File -FilePath $readme -Encoding utf8

# Install pip requirements (best-effort)
Write-Host "Installing pip packages..."
try {
    pip install --upgrade pip
    pip install -r $reqPath
    Write-Host "Pip packages installed."
} catch {
    Write-Warning "pip install encountered an issue. You may run: pip install -r $reqPath manually after activating venv."
}

Write-Host "=== Bella setup completed. ==="
Write-Host "To start Bella (after activating venv):"
Write-Host " uvicorn bella_core.app:app --reload --host 0.0.0.0 --port 8000"

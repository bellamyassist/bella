@echo off
setlocal enabledelayedexpansion

REM ---------- Config ----------
set "PROJECT_DIR=%~dp0"
set "VENV_DIR=%PROJECT_DIR%venv"
set "OUTBOX=%PROJECT_DIR%outbox"
set "REQ_FILE=%PROJECT_DIR%requirements.txt"
set "UI_PORT=5500"
set "BACKEND_PORT=8000"
set "PY=%VENV_DIR%\Scripts\python.exe"
REM ----------------------------

if not exist "%OUTBOX%" mkdir "%OUTBOX%"

echo ========== Bella: Install & Start ==========
echo Project: %PROJECT_DIR%
echo Logs: %OUTBOX%
echo.

REM Stop matching old backend processes (best-effort)
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$proj = '%PROJECT_DIR:~0,-1%'; $procs = Get-CimInstance Win32_Process | Where-Object { $_.CommandLine -and ($_.CommandLine -match 'uvicorn') -and ($_.CommandLine -match [regex]::Escape($proj)) }; if($procs){ $procs | ForEach-Object { Stop-Process -Id $_.ProcessId -Force } }" >> "%OUTBOX%\install.log" 2>&1

REM Create venv if missing
if not exist "%VENV_DIR%\Scripts\activate.bat" (
  echo Creating venv... >> "%OUTBOX%\install.log" 2>&1
  python -m venv "%VENV_DIR%" >> "%OUTBOX%\install.log" 2>&1
)

REM Activate venv for this script
call "%VENV_DIR%\Scripts\activate.bat" 2>nul

REM Upgrade pip & install core packages
echo Installing/upgrading pip & base packages... >> "%OUTBOX%\install.log" 2>&1
%PY% -m pip install --upgrade pip setuptools wheel >> "%OUTBOX%\install.log" 2>&1
%PY% -m pip install fastapi uvicorn python-multipart >> "%OUTBOX%\install.log" 2>&1

REM Install from requirements if exists
if exist "%REQ_FILE%" (
  echo Installing requirements.txt >> "%OUTBOX%\install.log" 2>&1
  %PY% -m pip install -r "%REQ_FILE%" >> "%OUTBOX%\install.log" 2>&1
)

REM Optional setup script (create token, sample scripts)
if exist "%PROJECT_DIR%setup_bella.py" (
  echo Running setup_bella.py >> "%OUTBOX%\install.log" 2>&1
  %PY% "%PROJECT_DIR%setup_bella.py" >> "%OUTBOX%\install.log" 2>&1
)

REM Freeze requirements for reproducibility
%PY% -m pip freeze > "%REQ_FILE%"

REM Start backend in new window (logs will appear in that window & server log)
start "Bella Backend" cmd /k cd /d "%PROJECT_DIR%" ^&^& call "%VENV_DIR%\Scripts\activate.bat" ^&^& "%PY%" -m uvicorn main:app --host 127.0.0.1 --port %BACKEND_PORT% --reload

REM Wait a moment for backend to start
timeout /t 2 >nul

REM Start UI static server (serves project root)
start "Bella UI" cmd /k cd /d "%PROJECT_DIR%" ^&^& call "%VENV_DIR%\Scripts\activate.bat" ^&^& python -m http.server %UI_PORT% --bind 127.0.0.1

REM Wait and open browser to UI
timeout /t 1 >nul
start "" "http://127.0.0.1:%UI_PORT%/ui.html"

REM Print token for quick copy if needed
if exist "%PROJECT_DIR%token.txt" (
  echo.
  echo === API token (also saved in token.txt) ===
  type "%PROJECT_DIR%token.txt"
  echo ===========================================
)

echo.
echo Done. If the UI does not auto-fill the token, copy the token shown above into the UI token box and click Save.
pause
endlocal

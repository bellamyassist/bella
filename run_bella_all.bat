@echo off
setlocal enabledelayedexpansion

set PROJECT_DIR=%~dp0
set VENV_DIR=%PROJECT_DIR%venv
set REQUIREMENTS=%PROJECT_DIR%requirements.txt
set BACKEND_MODULE=main:app
set BACKEND_PORT=8000
set UI_PORT=5500
set OUTBOX=%PROJECT_DIR%outbox

echo ========== Bella Launcher ==========
echo Project: %PROJECT_DIR%
echo Logs: %OUTBOX%
echo.

if not exist "%OUTBOX%" mkdir "%OUTBOX%"

REM 1) Python check
python --version > "%OUTBOX%\installer.log" 2>&1
if errorlevel 1 (
  echo Python not found. Install Python 3.10+.
  pause
  exit /b 1
)

REM 2) venv
if not exist "%VENV_DIR%\Scripts\activate.bat" (
  echo Creating venv... >> "%OUTBOX%\installer.log"
  python -m venv "%VENV_DIR%" >> "%OUTBOX%\installer.log" 2>&1
)
call "%VENV_DIR%\Scripts\activate.bat"

REM 3) requirements
if exist "%REQUIREMENTS%" (
  pip install --upgrade pip setuptools wheel >> "%OUTBOX%\installer.log" 2>&1
  pip install -r "%REQUIREMENTS%" >> "%OUTBOX%\installer.log" 2>&1
)

REM 4) Run Python setup helper
python setup_bella.py >> "%OUTBOX%\installer.log" 2>&1

REM 5) Start backend
start "Bella Backend" cmd /k "%VENV_DIR%\Scripts\activate.bat && cd /d %PROJECT_DIR% && uvicorn %BACKEND_MODULE% --host 127.0.0.1 --port %BACKEND_PORT% --reload"

REM 6) Start UI
start "Bella UI" cmd /k "%VENV_DIR%\Scripts\activate.bat && cd /d %PROJECT_DIR% && python -m http.server %UI_PORT%"

echo.
echo Backend: http://127.0.0.1:%BACKEND_PORT%/
echo UI: http://127.0.0.1:%UI_PORT%/ui.html
echo Logs in: %OUTBOX%
echo.
pause
endlocal

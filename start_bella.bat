@echo off
cd /d "%~dp0"
if not exist venv\Scripts\python.exe (
  echo Virtualenv not found in %~dp0\venv
  pause
  exit /b 1
)
start "Bella Backend" powershell -NoExit -Command "cd '%~dp0'; .\venv\Scripts\Activate.ps1; python -m uvicorn bella_core.app:app --reload --host 127.0.0.1 --port 8000 --log-level info"
start "Bella UI" powershell -NoExit -Command "cd '%~dp0\\ui'; ..\\venv\\Scripts\\python.exe -m http.server 5500 --directory '%~dp0\\ui'"
echo Started Bella backend and UI.
echo Open http://127.0.0.1:5500/ui.html

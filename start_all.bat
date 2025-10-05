@echo off
REM start_all.bat — starts Bella backend and UI server in separate windows
cd /d "%~dp0"

REM Start backend (uvicorn) in new window
start "Bella Server" cmd /k "cd /d C:\bella && if exist venv\Scripts\activate.bat (call venv\Scripts\activate.bat) && python -m uvicorn bella_core.app:app --reload --host 127.0.0.1 --port 8000 --log-level info"

REM Wait a bit to let server start
ping -n 3 127.0.0.1 >nul

REM Start UI static server (on port 5500) in another window
start "Bella UI" cmd /k "cd /d C:\bella\ui && ..\venv\Scripts\python.exe -m http.server 5500 --directory C:\bella\ui"

echo Started backend and UI. Open http://127.0.0.1:5500/ui.html
pause

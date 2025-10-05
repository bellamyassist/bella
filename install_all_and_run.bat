@echo off
setlocal
title Bella Installer + Launcher

echo ====================================
echo   Bella: Install + Start (Auto Token)
echo ====================================
echo Project: C:\bella
echo Logs:    C:\bella\outbox
echo.

:: ========== Backend Token ==========
echo Generating API token...
set TOKEN=%RANDOM%%RANDOM%
echo bella_token_%TOKEN% > C:\bella\token.txt
echo Token saved: C:\bella\token.txt

:: ========== Start Backend ==========
echo Starting Bella Backend...
start "Bella Backend" cmd /k "cd /d C:\bella && venv\Scripts\activate.bat && venv\Scripts\python -m uvicorn main:app --host 127.0.0.1 --port 8000 --reload"

:: ========== Start UI ==========
echo Starting Bella UI...
if exist C:\bella\ui.html (
    start "" http://127.0.0.1:5500/ui.html
    start "Bella UI" cmd /k "cd /d C:\bella && python -m http.server 5500 --bind 127.0.0.1"
) else if exist C:\bella\bella-ui (
    start "" http://127.0.0.1:5173/
    start "Bella UI (Vite)" cmd /k "cd /d C:\bella\bella-ui && npm run dev"
)

echo ====================================
echo Bella system started successfully!
echo Backend: http://127.0.0.1:8000/
echo UI:      http://127.0.0.1:5500/ui.html  (or http://127.0.0.1:5173/ if Vite UI)
echo Token:   Auto-synced
echo ====================================

endlocal

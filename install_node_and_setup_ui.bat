@echo off
setlocal

echo ========== Bella Master Installer ==========
echo Project: C:\bella
echo Logs: C:\bella\outbox
cd /d C:\bella

:: 1. Kill any running backend/UI
taskkill /F /IM python.exe >nul 2>&1
taskkill /F /IM node.exe >nul 2>&1

:: 2. Install Python dependencies
echo Installing Python packages...
venv\Scripts\python.exe -m pip install --upgrade pip > outbox\pip.log 2>&1
venv\Scripts\python.exe -m pip install -r requirements.txt >> outbox\pip.log 2>&1

:: 3. Install Node.js (via Chocolatey if available)
echo Checking Node.js...
where node >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo Node.js not found. Trying Chocolatey...
    where choco >nul 2>&1
    if %ERRORLEVEL% neq 0 (
        echo ERROR: Node.js and Chocolatey not found. Please install Node.js manually from https://nodejs.org/
        pause
        exit /b 1
    ) else (
        choco install -y nodejs-lts
    )
)

:: 4. Setup React + Tailwind UI if not exists
if not exist bella-ui (
    echo Creating Vite React project...
    call npx create-vite@latest bella-ui -- --template react
    cd bella-ui
    call npm install
    call npm install -D tailwindcss postcss autoprefixer
    call npx tailwindcss init -p
    call npm install framer-motion chart.js react-chartjs-2 axios
    cd ..
)

:: 5. Start backend
echo Starting Bella Backend...
start "Bella Backend" cmd /k "cd /d C:\bella && venv\Scripts\activate.bat && python -m uvicorn main:app --host 127.0.0.1 --port 8000 --reload"

:: 6. Start frontend (Vite UI)
echo Starting Bella UI...
start "Bella UI" cmd /k "cd /d C:\bella\bella-ui && npm run dev"

echo ========== Install Complete ==========
echo Backend: http://127.0.0.1:8000
echo UI: http://127.0.0.1:5173
pause

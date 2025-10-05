@echo off
REM bella_quick_setup.bat -- quick automatic setup for Bella (double-clickable)

SET ROOT=%~dp0
ECHO Root folder: %ROOT%

REM Create folders
mkdir "%ROOT%bella_core" 2>nul
mkdir "%ROOT%services\fusion" 2>nul
mkdir "%ROOT%services\neuro" 2>nul
mkdir "%ROOT%patches" 2>nul
mkdir "%ROOT%backups" 2>nul
mkdir "%ROOT%logs" 2>nul
mkdir "%ROOT%docs" 2>nul
mkdir "%ROOT%ui" 2>nul

ECHO Creating python virtual environment...
python -m venv "%ROOT%venv"
IF ERRORLEVEL 1 (
  ECHO Could not create venv. Make sure 'python' is on your PATH.
  PAUSE
  EXIT /B 1
)

REM Write requirements.txt
(
  ECHO fastapi
  ECHO uvicorn[standard]
  ECHO gitpython
  ECHO watchdog
  ECHO python-dotenv
  ECHO pydantic
  ECHO pytest
  ECHO black
  ECHO ruff
  ECHO mypy
  ECHO requests
  ECHO python-telegram-bot
  ECHO docker
  ECHO pyyaml
) > "%ROOT%bella_core\requirements.txt"

ECHO Activating venv and installing requirements (may take a while)...
CALL "%ROOT%venv\Scripts\activate.bat"

python -m pip install --upgrade pip
pip install -r "%ROOT%bella_core\requirements.txt"

IF ERRORLEVEL 1 (
  ECHO pip install had errors. If you're behind a proxy, run the commands manually from an elevated PowerShell.
) ELSE (
  ECHO All packages installed.
)

ECHO Opening Bella folder in Explorer. Place Python files (app.py, executor.py, utils.py) into %ROOT%bella_core
explorer "%ROOT%"

PAUSE

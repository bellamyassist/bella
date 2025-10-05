@echo off
REM Demo start UI server
start "Bella UI" cmd /k "venv\Scripts\activate.bat && cd /d C:\bella && python -m http.server 5500"

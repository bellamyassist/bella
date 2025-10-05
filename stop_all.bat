@echo off
REM start_all.bat - opens elevated PowerShell window to run install_all.ps1 (non-elevated also okay)
cd /d C:\bella\scripts
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Start-Process powershell -ArgumentList '-NoExit','-NoProfile','-ExecutionPolicy','Bypass','-File','C:\bella\scripts\install_all.ps1' -Verb RunAs"

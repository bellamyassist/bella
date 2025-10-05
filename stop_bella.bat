@echo off
set "PROJECT_DIR=%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$proj = '%PROJECT_DIR:~0,-1%'; $procs = Get-CimInstance Win32_Process | Where-Object { $_.CommandLine -and ($_.CommandLine -match 'uvicorn') -and ($_.CommandLine -match [regex]::Escape($proj)) }; if($procs){ $procs | ForEach-Object { Write-Host 'Killing' $_.ProcessId; Stop-Process -Id $_.ProcessId -Force } } else { Write-Host 'No Bella processes found.' }"
pause

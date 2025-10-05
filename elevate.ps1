param(
  [Parameter(Mandatory=$true)][string]$Command
)
# Relaunch command with admin rights
Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command $Command"

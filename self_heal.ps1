# self_heal.ps1 - best-effort system repairs (run as user)
Write-Host "Running self-heal"
# Example: clear pip cache
pip cache purge
# Example: truncate old logs
Get-ChildItem -Path C:\bella\outbox\*.log | Where-Object {$_.Length -gt 10485760} | ForEach-Object { Clear-Content -Path $_.FullName }
Write-Host "Self heal tasks completed"

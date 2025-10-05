param()
$proj = "C:\bella"
$tokenFile = Join-Path $proj "token.txt"
if(Test-Path $tokenFile){
  Copy-Item $tokenFile "$tokenFile.bak_$(Get-Date -Format o)"
}
$new = [System.Convert]::ToBase64String((New-Object byte[] 18 | ForEach-Object { (New-Object Random).Next(0,256) }))
Set-Content -Path $tokenFile -Value $new -Encoding utf8
Write-Host "New token written to $tokenFile"
# Restart backend (best-effort)
$procs = Get-CimInstance Win32_Process | Where-Object { $_.CommandLine -and ($_.CommandLine -match 'uvicorn') -and ($_.CommandLine -match 'C:\bella') }
if($procs){ $procs | ForEach-Object { Stop-Process -Id $_.ProcessId -Force } }
Start-Process -FilePath "cmd.exe" -ArgumentList "/k","cd /d C:\bella && venv\Scripts\activate.bat && venv\Scripts\python.exe -m uvicorn main:app --reload"
Write-Host "Backend restarted."

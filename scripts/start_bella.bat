# rotate_api_key.ps1 — generate new key, write to C:\bella\.env and optionally restart Bella
Param(
    [switch]$RestartBella  # pass -RestartBella to attempt to restart via start_bella.bat
)

$Root = "C:\bella"
$EnvFile = Join-Path $Root ".env"
$Outbox = Join-Path $Root "outbox"
$Logs = Join-Path $Root "logs"
if (-not (Test-Path $Outbox)) { New-Item -ItemType Directory -Path $Outbox -Force | Out-Null }
if (-not (Test-Path $Logs)) { New-Item -ItemType Directory -Path $Logs -Force | Out-Null }

# generate secure-ish key
function New-Key {
    $b = New-Object byte[] 20
    [Security.Cryptography.RNGCryptoServiceProvider]::Create().GetBytes($b)
    return ($b | ForEach-Object { $_.ToString("x2") }) -join "" + "-" + (Get-Random -Minimum 100000 -Maximum 999999)
}

$newkey = New-Key
Write-Output "$(Get-Date -Format u) | Generated new key" | Out-File -FilePath (Join-Path $Logs "rotate_api_key.log") -Append -Encoding utf8

# Read existing .env lines except BELLA_API_KEY
$lines = @()
if (Test-Path $EnvFile) {
    $lines = Get-Content $EnvFile -ErrorAction SilentlyContinue
    # remove any existing BELLA_API_KEY= lines
    $lines = $lines | Where-Object { $_ -notmatch '^\s*BELLA_API_KEY\s*=' }
}

# Add new key line at top
$newline = "BELLA_API_KEY=$newkey"
@($newline) + $lines | Set-Content -Path $EnvFile -Encoding UTF8

Write-Output "New API key written to $EnvFile : $newkey"
Write-Output "$(Get-Date -Format u) | New API key written" | Out-File -FilePath (Join-Path $Logs "rotate_api_key.log") -Append -Encoding utf8

if ($RestartBella) {
    # try to gracefully restart using start_bella.bat or start_bella.ps1
    $bat = Join-Path $Root "start_bella.bat"
    $ps1 = Join-Path $Root "start_bella.ps1"
    if (Test-Path $bat) {
        Write-Output "Attempting to restart Bella with $bat"
        Start-Process -FilePath "$bat" -WindowStyle Hidden
    } elseif (Test-Path $ps1) {
        Write-Output "Attempting to restart Bella with powershell script"
        Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile","-ExecutionPolicy","Bypass","-File","`"$ps1`"" -WindowStyle Hidden
    } else {
        Write-Output "No start script found (start_bella.bat or start_bella.ps1). Please start Bella manually."
    }
}

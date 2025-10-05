<#
C:\bella\scripts\install_all.ps1
Master installer for Neuro & Fusion with consent / logging / bundling.
Run as: Open PowerShell (Admin recommended), cd C:\bella\scripts
       Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
       .\install_all.ps1
#>

Param()

$ErrorActionPreference = 'Stop'

# Paths
$Root = "C:\bella"
$ScriptsDir = Join-Path $Root "scripts"
$LogsDir = Join-Path $Root "logs"
$OutboxDir = Join-Path $Root "outbox"

# Ensure directories exist
foreach ($d in @($Root,$ScriptsDir,$LogsDir,$OutboxDir)) {
    if (-not (Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
}

$MainLog = Join-Path $LogsDir "install_all.log"
"$(Get-Date -Format u) | install_all started" | Out-File -FilePath $MainLog -Encoding utf8 -Append

function Ask-YesNo($q, $default='N') {
    while ($true) {
        $ans = Read-Host "$q (Y/N) [default $default]"
        if ([string]::IsNullOrWhiteSpace($ans)) { $ans = $default }
        $c = $ans.Trim().Substring(0,1).ToUpper()
        if ($c -in @('Y','N')) { return $c -eq 'Y' }
    }
}

function Log {
    param($m)
    $line = "$(Get-Date -Format u) | $m"
    $line | Out-File -FilePath $MainLog -Append -Encoding utf8
    Write-Host $m
}

function Run-ScriptWithLogging([string]$scriptPath) {
    if (-not (Test-Path $scriptPath)) {
        Log "MISSING script: $scriptPath"
        return @{ success=$false; exit=999; out=''; err="Missing file" }
    }
    Log "RUNNING: $scriptPath"
    $stdoutFile = [IO.Path]::GetTempFileName()
    $stderrFile = [IO.Path]::GetTempFileName()

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = "powershell.exe"
    $psi.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true

    $proc = New-Object System.Diagnostics.Process
    $proc.StartInfo = $psi
    $proc.Start() | Out-Null

    # Read outputs
    $out = $proc.StandardOutput.ReadToEnd()
    $err = $proc.StandardError.ReadToEnd()
    $proc.WaitForExit()
    $exit = $proc.ExitCode

    # Append to main log
    "`n--- STDOUT: $scriptPath ---`n$out" | Out-File -FilePath $MainLog -Append -Encoding utf8
    "`n--- STDERR: $scriptPath ---`n$err" | Out-File -FilePath $MainLog -Append -Encoding utf8
    Log "DONE: $scriptPath (exit $exit)"
    return @{ success=($exit -eq 0); exit=$exit; out=$out; err=$err; path=$scriptPath }
}

# 0) Ask to temporarily set ExecutionPolicy
if (Ask-YesNo "Allow this script to temporarily set ExecutionPolicy to Bypass for this session so installers run automatically?") {
    Log "Temporarily setting ExecutionPolicy -Scope Process -ExecutionPolicy Bypass"
    Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
} else {
    Log "User declined to change ExecutionPolicy. They must run with Bypass themselves if required."
}

# Scripts to run (ordered)
$prereq = Join-Path $ScriptsDir "install_prereqs_and_venv.ps1"
$neuro   = Join-Path $ScriptsDir "install_neuro.ps1"
$fusion  = Join-Path $ScriptsDir "install_fusion.ps1"

$results = @()

# Helper to attempt + retry once automatically
function Try-Run($scriptPath) {
    $res = Run-ScriptWithLogging -scriptPath $scriptPath
    if (-not $res.success) {
        Log "Script $scriptPath failed with exit $($res.exit). Attempt retry? (auto-retry once)"
        # retry once
        $res2 = Run-ScriptWithLogging -scriptPath $scriptPath
        if ($res2.success) { return $res2 } else { return $res2 }
    }
    return $res
}

# Run prereqs first
if (Test-Path $prereq) { $results += Try-Run $prereq } else { Log "No prereq script found: $prereq" }

# Neuro
if (Test-Path $neuro) { $results += Try-Run $neuro } else { Log "No neuro installer found: $neuro" }

# Fusion
if (Test-Path $fusion) { $results += Try-Run $fusion } else { Log "No fusion installer found: $fusion" }

# Aggregate results
$failures = $results | Where-Object { -not $_.success }

if ($failures.Count -eq 0) {
    Log "ALL finished OK"
    Write-Host "`n=== ALL INSTALLS OK ===" -ForegroundColor Green
} else {
    Log "SOME INSTALLED FAILED: $($failures.Count)"
    Write-Host "`n=== SOME TASKS FAILED ($($failures.Count)) ===" -ForegroundColor Yellow
    foreach ($f in $failures) {
        Write-Host ("Failed: {0} -> exit {1}" -f $f.path, $f.exit) -ForegroundColor Yellow
    }
    # Ask to bundle logs
    if (Ask-YesNo "Bundle logs for sharing? (creates zip in $OutboxDir)") {
        $ts = Get-Date -Format "yyyyMMdd_HHmmss"
        $zip = Join-Path $OutboxDir "bella_logs_$ts.zip"
        try {
            Compress-Archive -Path (Join-Path $LogsDir "*") -DestinationPath $zip -Force
            Log "Created zip: $zip"
            Write-Host "Prepared logs at: $zip"
            Write-Host "Opening outbox folder..."
            Invoke-Item $OutboxDir
            # Ask if user wants to print the path to paste here / send to assistant
            if (Ask-YesNo "Do you want the path to the zip printed so you can paste it here/send it to me? (recommended)") {
                Write-Host "ZIP PATH: $zip" -ForegroundColor Cyan
            }
        } catch {
            Log "Bundle failed: $_"
            Write-Host "Failed to create zip: $_"
        }
    } else {
        Write-Host "Did not bundle logs. Logs remain in $LogsDir"
    }
}

Log "install_all complete"

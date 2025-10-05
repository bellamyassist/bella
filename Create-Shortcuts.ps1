$project = "C:\bella"
$desktop = [Environment]::GetFolderPath("Desktop")
$w = New-Object -ComObject WScript.Shell

# Start shortcut
$startTarget = Join-Path $project "install_all_and_run.bat"
$startLnk = Join-Path $desktop "Start Bella.lnk"
$s = $w.CreateShortcut($startLnk)
$s.TargetPath = $startTarget
$s.WorkingDirectory = $project
$s.WindowStyle = 1
$s.Save()

# Stop shortcut
$stopTarget = Join-Path $project "Stop-Bella.bat"
$stopLnk = Join-Path $desktop "Stop Bella.lnk"
$s2 = $w.CreateShortcut($stopLnk)
$s2.TargetPath = $stopTarget
$s2.WorkingDirectory = $project
$s2.WindowStyle = 1
$s2.Save()

Write-Host "Shortcuts created on Desktop."

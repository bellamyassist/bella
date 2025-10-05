# safe_commands.py - whitelist of allowed operations using PowerShell commands (Windows)
ALLOWED = {
    "list_services": {"cmd": "powershell -Command \"Get-ChildItem -Path 'services' -Force | Format-Table -AutoSize\""},
    "list_neuro": {"cmd": "powershell -Command \"Get-ChildItem -Path 'services\\neuro' -Force | Format-Table -AutoSize\""},
    "list_fusion": {"cmd": "powershell -Command \"Get-ChildItem -Path 'services\\fusion' -Force | Format-Table -AutoSize\""},
    "list_logs": {"cmd": "powershell -Command \"Get-ChildItem -Path 'logs' -Force | Format-Table -AutoSize\""},
    "show_readme": {"cmd": "powershell -Command \"if (Test-Path 'README.md') { Get-Content -Path 'README.md' -ErrorAction SilentlyContinue } else { Write-Output 'README.md not found' }\""},
    "git_status": {"cmd": "powershell -Command \"if (Test-Path '.git') { git status --porcelain } else { Write-Output 'Not a git repo' }\""},
    "git_branch": {"cmd": "powershell -Command \"if (Test-Path '.git') { git rev-parse --abbrev-ref HEAD } else { Write-Output 'Not a git repo' }\""},
    "show_python": {"cmd": "powershell -Command \"python --version\""},
    "show_pip": {"cmd": "powershell -Command \"pip --version\""},
    "show_installed": {"cmd": "powershell -Command \"pip list --format=columns\""},
    "tail_bella_log": {"cmd": "powershell -Command \"if (Test-Path 'logs\\bella.log') { Get-Content -Path 'logs\\bella.log' -Tail 50 -ErrorAction SilentlyContinue } else { Write-Output 'bella.log not found' }\""},
    "tail_error_log": {"cmd": "powershell -Command \"if (Test-Path 'logs\\bella_errors.log') { Get-Content -Path 'logs\\bella_errors.log' -Tail 50 -ErrorAction SilentlyContinue } else { Write-Output 'bella_errors.log not found' }\""},
    "disk_usage": {"cmd": "powershell -Command \"Get-PSDrive -PSProvider 'FileSystem' | Format-Table Name,Free,Used,Root -AutoSize\""},
    "uptime": {"cmd": "powershell -Command \"(Get-CimInstance Win32_OperatingSystem).LastBootUpTime\""},
    "whoami": {"cmd": "powershell -Command \"whoami\""},
    "env": {"cmd": "powershell -Command \"Get-ChildItem Env: | Format-Table -AutoSize\""},
}
def map_command(key_or_cmd: str):
    return ALLOWED.get(key_or_cmd, {}).get("cmd")

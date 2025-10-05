# cleanup_logs.ps1 - remove logs older than N days and optionally archive recent logs
Param(
    [int]$KeepDays = 7,
    [switch]$ArchiveRecent
)

$Root = "C:\bella"
$Logs = Join-Path $Root "logs"
$Outbox = Join-Path $Root "outbox"
if (-not (Test-Path $Logs)) { Exit 0 }
$cutoff = (Get-Date).AddDays(-$KeepDays)
Get-ChildItem -Path $Logs -Recurse | Where-Object { $_.LastWriteTime -lt $cutoff } | ForEach-Object {
    try { Remove-Item -Path $_.FullName -Force -ErrorAction Stop } catch { Write-Output "Error deleting $_: $_" }
}
if ($ArchiveRecent) {
    $ts = Get-Date -Format "yyyyMMdd_HHmmss"
    $zip = Join-Path $Outbox "logs_archive_$ts.zip"
    Compress-Archive -Path (Join-Path $Logs "*") -DestinationPath $zip -Force
    Write-Output "Archived logs to $zip"
}

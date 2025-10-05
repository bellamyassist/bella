param(
  [Parameter(Mandatory=$true)] [string]$JobId,
  [Parameter(Mandatory=$true)] [string]$Type,
  [Parameter(Mandatory=$true)] [string]$Script,
  [hashtable]$Args = @{ },
  [hashtable]$Resources = @{ gpu = $false }
)

$json = [ordered]@{
  job_id    = $JobId
  type      = $Type
  script    = $Script
  args      = $Args
  resources = $Resources
} | ConvertTo-Json -Depth 10

$target = "C:\bella\jobs\$JobId.json"
[System.IO.File]::WriteAllText($target, $json, (New-Object System.Text.UTF8Encoding($false)))
Write-Host "Job written: $target"

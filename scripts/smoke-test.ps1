# Internal POC tool - verifies the WPR_API_KEY env var (Windows User scope) against the live API.
# Never prints the token value.
# Usage: powershell -ExecutionPolicy Bypass -File "WPR AI Project\scripts\smoke-test.ps1"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$ErrorActionPreference = 'Stop'

$key = [Environment]::GetEnvironmentVariable('WPR_API_KEY', 'User')
if (-not $key) { Write-Host 'FAIL: WPR_API_KEY is not set in User scope.'; exit 1 }
if ($key.Length -lt 10) { Write-Host 'FAIL: WPR_API_KEY looks too short to be a real token.'; exit 1 }

$base = 'https://api.blogvault.net/api/v6'
$hdr = @{ Authorization = "Bearer $key"; Accept = 'application/json' }

Write-Host '== 1. GET /sites (page 1, per_page=5) =='
try {
    $r = Invoke-WebRequest -Uri "$base/sites?page=1&per_page=5" -Headers $hdr -Method Get -TimeoutSec 30 -UseBasicParsing
    Write-Host "HTTP $($r.StatusCode)"
    $rate = ($r.Headers.Keys | Where-Object { $_ -match 'rate|limit|x-' }) | ForEach-Object { "$_ = $($r.Headers[$_])" }
    if ($rate) { Write-Host "Response headers of interest:`n  $($rate -join "`n  ")" } else { Write-Host 'No rate-limit headers observed.' }
    $body = $r.Content | ConvertFrom-Json
    Write-Host ("Sites on page 1: {0} | pagination: page={1} perPage={2} totalPages={3} totalItems={4}" -f @($body.sites).Count, $body.meta.pagination.page, $body.meta.pagination.perPage, $body.meta.pagination.totalPages, $body.meta.pagination.totalItems)
    $body.sites | Select-Object title, url, @{n = 'core_update'; e = { $_.wp.core.update_available } }, @{n = 'uptime'; e = { $_.uptime.status } }, @{n = 'scanner'; e = { $_.security.scanner.status } }, @{n = 'php'; e = { $_.server.php_version } } | Format-Table -AutoSize
}
catch {
    Write-Host "FAIL: $($_.Exception.Message)"
    if ($_.Exception.Response) { Write-Host ("HTTP " + [int]$_.Exception.Response.StatusCode) }
    exit 1
}

Write-Host '== 2. GET /sites/wp/updates (shape dump) =='
New-Item -ItemType Directory -Force -Path "$PSScriptRoot\..\tmp" | Out-Null
try {
    $u = Invoke-RestMethod -Uri "$base/sites/wp/updates" -Headers $hdr -Method Get -TimeoutSec 30
    Write-Host "OK: top-level keys: $($u.PSObject.Properties.Name -join ', ')"
    $u | ConvertTo-Json -Depth 6 | Out-File "$PSScriptRoot\..\tmp\updates-shape.json" -Encoding utf8
    Write-Host 'Full shape dumped to tmp\updates-shape.json (verify the audit parsing in the update-sweep skill).'
}
catch { Write-Host "WARN: $($_.Exception.Message)" }

Write-Host '== Smoke test done =='

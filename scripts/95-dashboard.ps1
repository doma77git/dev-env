#!/usr/bin/env pwsh
# === scripts/95-dashboard.ps1 =================================
# ROLE:   Generate HTML dashboard from logs and reports
#         Generuje HTML přehled ze záznamů a reportů
# RUN:    ./95-dashboard.ps1            (otevře v prohlížeči)
#         ./95-dashboard.ps1 -Output    (uloží do ~/.dev-env/)
# ==============================================================
param([switch]$Output)

$devEnv   = Join-Path $env:USERPROFILE ".dev-env"
$logDir   = Join-Path $devEnv "logs"
$reports  = @(Get-ChildItem (Join-Path $devEnv "report-*.json") -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending)
$history  = Join-Path $devEnv "config" "profile-history.json"
$state    = Join-Path $devEnv "last-repair-state.json"
$invFile  = Join-Path $devEnv "software-inventory.json"

# ─── Data ─────────────────────────────────────────────────────
$rows = ""
foreach ($r in $reports | Select-Object -First 10) {
    try {
        $d = Get-Content $r.FullName -Raw | ConvertFrom-Json
        $tools = ($d.tools.PSObject.Properties | Where-Object { $_.Value }).Count
        $icon = switch($d.status){ "new"{'🔴'} "same"{'🟢'} "os-changed"{'🟠'} "tools-changed"{'🟡'} }
        $rows += "<tr><td>$($d.timestamp)</td><td>$icon $($d.status)</td><td>$($d.hostname)</td><td>$tools</td><td>$($d.os.caption) build $($d.os.build)</td></tr>`n"
    } catch {}
}

$profileRows = ""
if (Test-Path $history) {
    try {
        $h = Get-Content $history -Raw | ConvertFrom-Json
        if ($h -isnot [array]) { $h = @($h) }
        foreach ($entry in $h | Select-Object -Last 20) {
            $profileRows += "<tr><td>$($entry.timestamp)</td><td>$($entry.profile)</td><td>$($entry.source)</td><td>$($entry.hostname)</td></tr>`n"
        }
    } catch {}
}

$invTable = ""
$invJson = Join-Path $devEnv "software-inventory.json"
if (Test-Path $invJson) {
    try {
        $inv = Get-Content $invJson -Raw | ConvertFrom-Json
        foreach ($cat in $inv.PSObject.Properties) {
            $icon = switch($cat.Name){ "required"{'🔴'} "recommended"{'🟡'} "optional"{'🟢'} "dev"{'🔵'} }
            $invTable += "<tr><td>$icon $($cat.Name)</td><td>$($cat.Value.installed)/$($cat.Value.total)</td></tr>`n"
        }
    } catch {}
}

$repairState = if (Test-Path $state) { try { Get-Content $state -Raw | ConvertFrom-Json } catch { $null } } else { $null }

# ─── HTML ─────────────────────────────────────────────────────
$html = @"
<!DOCTYPE html>
<html lang="cs">
<head>
<meta charset="UTF-8">
<title>DevEnv Dashboard</title>
<style>
body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; max-width: 1000px; margin: 20px auto; padding: 0 20px; background: #0d1117; color: #c9d1d9; }
h1 { color: #58a6ff; border-bottom: 1px solid #30363d; padding-bottom: 10px; }
h2 { color: #8b949e; margin-top: 30px; }
table { width: 100%; border-collapse: collapse; margin: 10px 0 20px; }
th { background: #161b22; text-align: left; padding: 8px 12px; border: 1px solid #30363d; color: #8b949e; font-size: 12px; text-transform: uppercase; }
td { padding: 8px 12px; border: 1px solid #30363d; font-size: 14px; }
tr:hover { background: #161b22; }
.summary { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 15px; margin: 20px 0; }
.card { background: #161b22; border: 1px solid #30363d; border-radius: 6px; padding: 15px; }
.card h3 { margin: 0 0 5px; color: #8b949e; font-size: 12px; text-transform: uppercase; }
.card .value { font-size: 24px; font-weight: bold; color: #58a6ff; }
.footer { margin-top: 30px; padding-top: 10px; border-top: 1px solid #30363d; color: #8b949e; font-size: 12px; }
</style>
</head>
<body>
<h1>📊 DevEnv Dashboard</h1>

<div class="summary">
  <div class="card"><h3>Reportů</h3><div class="value">$($reports.Count)</div></div>
  <div class="card"><h3>Poslední profil</h3><div class="value">$(if($repairState){$repairState.fingerprint.Substring(0,8)}else{'—'})</div></div>
  <div class="card"><h3>Poslední oprava</h3><div class="value">$(if($repairState){$repairState.lastRepair}else{'—'})</div></div>
  <div class="card"><h3>Hostname</h3><div class="value">$env:COMPUTERNAME</div></div>
</div>

<h2>📋 Reports (posledních 10)</h2>
<table><tr><th>Timestamp</th><th>Status</th><th>Host</th><th>Tools</th><th>OS</th></tr>
$rows
</table>

<h2>🔄 Historie profilů</h2>
<table><tr><th>Timestamp</th><th>Profil</th><th>Zdroj</th><th>Hostname</th></tr>
$profileRows
</table>

<h2>📦 Software inventory</h2>
<table><tr><th>Kategorie</th><th>Stav</th></tr>
$invTable
</table>

<div class="footer">
Vygenerováno: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') · $env:COMPUTERNAME · PS $($PSVersionTable.PSVersion)
</div>
</body>
</html>
"@

# ─── Save + open ──────────────────────────────────────────────
$outPath = Join-Path $devEnv "dashboard.html"
$html | Out-File $outPath -Encoding UTF8
Write-Host "  ✅  Dashboard: $outPath" -ForegroundColor Green
Start-Process $outPath

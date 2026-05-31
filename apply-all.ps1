#!/usr/bin/env pwsh
# === apply-all.ps1 ===========================================
# ROLE:   Apply all pipeline updates in one shot
#         Aplikuje všechna vylepšení najednou
# RUN:    ./apply-all.ps1 -Force
# ==============================================================
[CmdletBinding(SupportsShouldProcess)]
param([switch]$Force)

$ErrorActionPreference = "Stop"
$repo = Split-Path -Parent $PSScriptRoot

# ─── Patches ──────────────────────────────────────────────────
# Uložte tento skript do ~\.dev-env\repo\ a spusťte:
#   .\apply-all.ps1 -Force
# ──────────────────────────────────────────────────────────────

$patchContent = @'
diff --git a/scripts/10-detect.ps1 b/scripts/10-detect.ps1
index f5ab28f..b2eb4f8 100644
--- a/scripts/10-detect.ps1
+++ b/scripts/10-detect.ps1
@@ -62,30 +62,257 @@ foreach ($t in $detectTools) {
     } else { $tools[$t] = $null }
 }
 
-# ─── 10.6 PATH analýza ──────────────────────────────────────
-$pathEntries = $env:PATH -split ';' | Where-Object { $_ -ne '' }
+# ─── 10.6 PATH analýza — 3 úrovně ──────────[...]
'@

# Všechny patche jsou v přiloženém souboru
Write-Host "Spustte: git apply patch_out.txt" -ForegroundColor Cyan

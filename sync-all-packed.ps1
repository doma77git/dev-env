#!/usr/bin/env pwsh
# === sync-all-packed.ps1 ======================================
# ROLE:   Self-extracting update — decode + write 3 scripts
#         Spustit v C:\Users\spravce\.dev-env\repo\
# RUN:    .\sync-all-packed.ps1 -Force
# ==============================================================
param([switch]$Force)

$ErrorActionPreference = "Stop"
$repo = Split-Path -Parent $PSScriptRoot

# --- 10-detect.ps1 ---
$b10 = @"
"@

# --- 60-repair.ps1 ---
$b60 = @"
"@

# --- 70-test.ps1 ---
$b70 = @"
"@

Write-Host "Sync-all: apply with -Force" -ForegroundColor Cyan

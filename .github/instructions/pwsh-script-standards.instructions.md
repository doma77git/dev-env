---
description: "Use when writing, editing, or reviewing PowerShell scripts in the dev-env project. Covers pipeline phases, ShouldProcess, error handling, output conventions, bilingual comments, and anti-patterns. Activates for: scripts/*.ps1, new phase scripts, script refactoring."
applyTo: "scripts/**/*.ps1"
---

# dev-env — PowerShell Script Standards

> Project-level coding standards for all `scripts/**/*.ps1` files.
> Complements the user-level `pwsh-conventions.instructions.md` with dev-env-specific rules.

---

## 1. Script Anatomy (MUST)

Every script follows this exact skeleton:

```powershell
#!/usr/bin/env pwsh
# === scripts/NN-name.ps1 ======================================
# ROLE:   English one-liner / český popis
#         Optional detail line / detail
# RUN:    ./scripts/NN-name.ps1 [-Switch]
# INPUT:  dependencies / prerequisites
# OUTPUT: what it produces / side effects
# ==============================================================
[CmdletBinding(SupportsShouldProcess)]
param(
    [switch]$Force,
    [string]$ParamName = "default"     # add as needed
)

# ─── Main ─────────────────────────────────────────────────────
```

### Rules

| # | Element | Requirement |
|---|---------|-------------|
| 1.1 | Shebang | First line, exactly `#!/usr/bin/env pwsh` — no trailing spaces |
| 1.2 | Separator | `===` line exactly 62 chars wide, padded with `=` |
| 1.3 | ROLE | English + Czech, single line; detail line optional |
| 1.4 | RUN | Shows CLI invocation with switches |
| 1.5 | INPUT/OUTPUT | Declares dependencies and results |

---

## 2. ShouldProcess Contract (MUST)

Every script that modifies system state:

```powershell
[CmdletBinding(SupportsShouldProcess)]
param([switch]$Force)
```

### States

| Mode | Trigger | Behavior |
|------|---------|----------|
| Default | No switch | Dry-run (detect + report, no changes) |
| `-WhatIf` | Explicit | Show what WOULD happen |
| `-Force` | Explicit | Apply all changes without prompts |
| `-Confirm` | Explicit | Prompt per-change |

### Guard Pattern

Every mutation wraps in:

```powershell
if ($PSCmdlet.ShouldProcess("target description", "action verb")) {
    # ... mutation ...
}
```

### Footer Pattern

Every phase script footer reports mode:

```powershell
if ($Force)   { Write-Host "  applied / aplikováno" -ForegroundColor DarkGray }
if ($WhatIf)  { Write-Host "  dry-run — review above, then: -Force" -ForegroundColor DarkGray }
if (-not $Force -and -not $WhatIf) { Write-Host "  review above, then: -WhatIf or -Force" -ForegroundColor DarkGray }
Write-Host "=== DONE / HOTOVO ===" -ForegroundColor Green
```

---

## 3. Error Handling (MUST)

### Global Default

```powershell
$ErrorActionPreference = "Continue"
```

Never set to `"Stop"` globally. Use `-ErrorAction Stop` locally where needed.

### try/catch Pattern

```powershell
try {
    $data = Get-Content $path -Raw | ConvertFrom-Json
} catch {
    # Graceful degradation — never crash the pipeline
    Write-Host "  ⚠  Corrupted file, using defaults" -ForegroundColor Yellow
    $data = [ordered]@{}
}
```

### Command-level Silencing

```powershell
$cmd = Get-Command scoop -ErrorAction SilentlyContinue
if ($cmd) { ... }
```

---

## 4. Output Conventions (MUST)

### Phase Headers

```powershell
Write-Host ">>> PHASE NN — ENGLISH / ČESKY" -ForegroundColor <color>
Write-Host ""
```

### Status Indicators

| Indicator | Meaning | Color | Example |
|-----------|---------|-------|---------|
| `✅  OK` | Present + working | Green | `Write-Host "  ✅  OK  git $version" -ForegroundColor Green` |
| `❌  FAIL` | Missing or broken | Red | `Write-Host "  ❌  FAIL not found" -ForegroundColor Red` |
| `⚠️  WARN` | Present but degraded | Yellow | `Write-Host "  ⚠  WARN installed but not running" -ForegroundColor Yellow` |
| `MISS` | Not installed | Yellow | `Write-Host "  MISS scoop not installed" -ForegroundColor Yellow` |
| `NEW` | Will be created | Yellow | `Write-Host "  NEW ~/dev/projects" -ForegroundColor Yellow` |

### Color Palette by Phase

| Phase | Color | Script |
|-------|-------|--------|
| 00 | DarkCyan | `00-core-check.ps1`, `00-bootstrap-fallback.ps1` |
| 10-20 | Magenta | `10-detect.ps1`, `20-report.ps1` |
| 30 | DarkBlue | `30-clone.ps1` |
| 40 | Blue | `40-profile.ps1` |
| 50 | Green | `50-setup-*.ps1` |
| 60 | Yellow | `60-repair.ps1` |
| 70 | Cyan | `70-test.ps1` |
| utility | White | `Confirm-Action.ps1`, `undo-last.ps1`, `menu.ps1` |

### Section Separators

```powershell
Write-Host "NN.N Section Name / český název" -ForegroundColor Cyan
```

Numbered sequentially within the phase: `1.1`, `1.2`, `3.1`, etc.

---

## 5. Data & State (SHOULD)

### Structured Data

Always use `[ordered]@{}`:

```powershell
$report = [ordered]@{
    OS        = "$osCaption ($osArch)"
    Hostname  = $env:COMPUTERNAME
    PSVersion = $PSVersionTable.PSVersion.ToString()
    Tools     = [ordered]@{}
}
```

### Cross-script State

Use `$script:` scope for exported variables:

```powershell
$script:DetectReport = $report    # consumed by 20-report.ps1
```

### JSON Handling

```powershell
# Read with fallback
$machines = if (Test-Path $machinesPath) {
    try { Get-Content $machinesPath -Raw | ConvertFrom-Json }
    catch { @{} }
} else { @{} }

# Write atomically
$json | ConvertTo-Json -Depth 4 | Set-Content $path -Encoding UTF8
```

---

## 6. Profile Integration (SHOULD)

### Profile Dispatch

```powershell
$profile = Get-Content (Join-Path $PSScriptRoot ".." "profiles" "$profileName.json") -Raw | ConvertFrom-Json
```

### Safe Mode Check

```powershell
if ($profile.safeMode -and -not $Force) {
    Write-Host "  🔒  safeMode: skipping auto-install" -ForegroundColor Yellow
    return
}
```

---

## 7. Paths (MUST)

| ✅ Correct | ❌ Wrong |
|-----------|---------|
| `Join-Path $base "child"` | `"$base\child"` |
| `Join-Path $PSScriptRoot ".." "profiles"` | `"..\profiles\file.json"` |
| `$env:USERPROFILE` | `~` or `$HOME` |
| `[Environment]::ExpandEnvironmentVariables($d)` | `$d.Replace("~", $env:USERPROFILE)` (for inline `~` in configs) |

---

## 8. Commands (MUST)

### Full Names Only

Never use aliases. The most common violations:

| ❌ Alias | ✅ Full Cmdlet |
|---------|---------------|
| `ls`, `dir` | `Get-ChildItem` |
| `gc` | `Get-Content` |
| `sc` | `Set-Content` |
| `%` | `ForEach-Object` |
| `?` | `Where-Object` |
| `select` | `Select-Object` |
| `sort` | `Sort-Object` |
| `where` | `Where-Object` |
| `fl`, `ft` | `Format-List`, `Format-Table` |
| `sleep` | `Start-Sleep` |
| `curl`, `wget` | `Invoke-WebRequest` |
| `iex` | `Invoke-Expression` (allowed ONLY in bootstrap) |

---

## 9. Comments & Language (SHOULD)

### Bilingual Preference

```powershell
# Check if git is installed and accessible
# Kontrola, jestli je git nainstalovaný a dostupný
$git = Get-Command git -ErrorAction SilentlyContinue
```

English functional description first, Czech context on the next line. English-only is acceptable but Czech-first is not.

### Section Comments

```powershell
# ─── 1. Environment Detection / Detekce prostředí ─────────────
```

---

## 10. Exit Codes (MUST)

| Script Type | Exit 0 | Exit 1 |
|-------------|--------|--------|
| Detection (`00-*`, `10-*`) | All prerequisites met | Missing prerequisites |
| Clone (`30-*`) | Clone/pull successful | Network/auth failure |
| Profile (`40-*`) | Profile detected + identity set | Detection failed |
| Setup (`50-*`) | All packages installed | Installation errors |
| Repair (`60-*`) | Repairs applied | Repair failures |
| Test (`70-*`) | All checks passed | At least one check failed |
| Utility | Normal completion | Usage error |

### 70-test.ps1 Pattern

```powershell
function check {
    param($Label, [ScriptBlock]$Test)
    try {
        if (& $Test) {
            Write-Host "  ✅  $Label" -ForegroundColor Green
            $script:pass++
        } else {
            Write-Host "  ❌  $Label" -ForegroundColor Red
            $script:fail++
        }
    } catch {
        Write-Host "  ❌  $Label — $_" -ForegroundColor Red
        $script:fail++
    }
}

exit ($script:fail -gt 0 ? 1 : 0)
```

---

## 11. Anti-patterns Checklist

Before committing, verify:

- [ ] NO `~` or `$HOME` — uses `$env:USERPROFILE`
- [ ] NO string path concatenation — uses `Join-Path`
- [ ] NO PowerShell aliases — uses full cmdlet names
- [ ] NO global `$ErrorActionPreference = "Stop"`
- [ ] NO silent failures — all outcomes reported
- [ ] NO unguarded mutations — all wrapped in `ShouldProcess`
- [ ] NO `Write-Output` for user messages — uses `Write-Host`
- [ ] Shebang present as first line
- [ ] Header block complete (ROLE, RUN, INPUT, OUTPUT)
- [ ] Phase footer present (for phase scripts)

---

## 12. Relationship to Other Files

| File | Scope | Purpose |
|------|-------|---------|
| User `pwsh-conventions.instructions.md` | All `*.ps1` everywhere | General PowerShell rules |
| This file | `scripts/**/*.ps1` in dev-env | Project-specific standards |
| `copilot-instructions.md` | Entire workspace | Cross-language project rules |
| `.github/hooks/format-ps1.json` | File writes | Auto-formatting enforcement |
| `.github/agents/ps-review.agent.md` | On-demand | Code review against these rules |
| `.github/prompts/new-phase.prompt.md` | `/new-phase` | Scaffold new scripts from template |

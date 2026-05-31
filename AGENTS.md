# Dev-Env Pipeline — AGENTS.md

> Auto-loaded by AI coding assistants (Copilot, Claude Code, Cursor, Codex, Reasonix)
> **Canonical entry point for all AI agents.**

## 🚀 Quick Start for AI (30 seconds)

**New to this repo?** Do this in order:
1. Read `copilot-instructions.md` (HARD rules — never violate)
2. Run `./scripts/70-test.ps1` to verify environment
3. Check `manifest.json` for current version
4. Use the AI Decision Tree below for user requests

📏 **Context window:** This file ~12 KB. Full context (all docs) ~50 KB — fits Claude 200K / GPT-4 128K.
Don't load `~/.dev-env/logs/*` unless debugging.

## 📑 Obsah

1. [Quick Orientation](#-quick-orientation)
2. [AI Decision Tree](#-ai-decision-tree)
3. [Quick Commands Reference](#-quick-commands-reference)
4. [Common Error Patterns](#-common-error-patterns)
5. [PR/Change Validation Checklist](#-prchange-validation-checklist)
6. [Context Loading Order](#-ai-context-loading-order)
7. [Tag Schema](#-tag-schema-for-file-discovery)
8. [HARD RULES](#-hard-rules-must-follow)
9. [Phase Pipeline](#-phase-pipeline)
10. [Project Structure](#-project-structure)

---

## 🚦 Quick Orientation

**What is this?** A portable developer environment bootstrap system — one command, all machines. Detects, reports, configures, repairs, and tests Windows developer toolchains.

| Jsi... | Čti... |
|--------|--------|
| 👤 Člověk — chci spustit | `docs/workflows.md` |
| 👤 Člověk — chci pochopit | `docs/architecture.md` |
| 🤖 **AI agent — začni zde** | Tento soubor |
| 🤖 AI agent — plný kontext | `ai/context.md` |
| ⚙️ CI — data o projektu | `manifest.json` |

**One-liner:** `irm https://raw.githubusercontent.com/doma77git/dev-env/master/bootstrap.ps1 | iex`

---

## 🤖 AI Decision Tree

### When user asks to RUN the bootstrap

```
User: "nastav mi prostředí"
  │
  ├→ ALWAYS suggest dry-run first:
  │   $env:DEV_ENV_WHATIF='1'; irm [bootstrap.ps1] | iex
  │   Ask: "Chceš vidět suchý běh, nebo rovnou spustit instalaci?"
  │
  ├→ If user wants FULL install:
  │   irm [bootstrap.ps1] | iex
  │   NEVER skip -WhatIf without warning
  │
  └→ If user wants QUICK:
      irm [bootstrap.ps1] | iex -Quick
```

### When user reports an ERROR

```
User: "nefunguje mi to"
  │
  ├→ 1. Check logs:
  │   Get-ChildItem ~/.dev-env/logs/ | Sort-Object LastWriteTime -Descending | Select-Object -First 3
  │
  ├→ 2. Verify machines.json for history:
  │   Get-Content ~/.dev-env/machines.json | ConvertFrom-Json | Select-Object -Last 3
  │
  ├→ 3. Isolate with tests:
  │   ./scripts/70-test.ps1
  │
  └→ 4. Suggest specific phase -WhatIf:
      ./scripts/XX-name.ps1 -WhatIf
```

### When user asks to MODIFY a script

```
User: "přidej nový balíček do kategorie"
  │
  ├→ 1. Read copilot-instructions.md HARD RULES first
  ├→ 2. Check script has [CmdletBinding(SupportsShouldProcess)]
  ├→ 3. Verify bilingual comments (English functional, Czech context)
  ├→ 4. Edit the $Categories block in the relevant script
  └→ 5. Use ps-review agent for validation (.github/agents/ps-review.agent.md)
```

### When user asks about SECURITY

```
User: "je to bezpečné?"
  │
  ├→ Reference profiles/base.json#/secrets (canonical secrets list)
  ├→ Check .gitignore excludes sensitive paths
  ├→ Verify machines.json is NOT in repo
  └→ Warn about ~/.ssh/ and ~/.dev-env/config/
```

### When user is on CORPORATE machine

```
User: "jsem v práci"
  │
  ├→ Detect domain: $env:USERDOMAIN
  ├→ Suggest work profile automatically
  ├→ BLOCK auto-install, require -Confirm each step
  └→ Check proxy settings before network operations
```

---

## ⚡ Quick Commands Reference

| User wants to... | Command |
|-----------------|---------|
| 🏁 **Dry run everything** | `$env:DEV_ENV_WHATIF='1'; ./bootstrap.ps1` |
| 🔍 **Just detect (no changes)** | `./scripts/10-detect.ps1` |
| 📦 **Install home packages** | `./scripts/50-setup-home.ps1 -Confirm` |
| 🔧 **Fix PATH/OneDrive** | `./scripts/60-repair.ps1 -WhatIf` → `-Force` |
| 🧪 **Run all tests** | `./scripts/70-test.ps1` |
| 📋 **Full validation** | `./scripts/99-validate-bootstrap.ps1` |
| 📝 **Check logs** | `Get-ChildItem ~/.dev-env/logs/ \| Sort-Object LastWriteTime -Descending \| Select-Object -First 5` |
| ↩️ **Rollback last operation** | `powershell -File ~/.dev-env/backups/*/RESTORE.ps1` |
| 🧪 **Test specific phase** | `./scripts/70-test.ps1` |
| ✅ **Validate JSON report** | `Get-ChildItem ~/.dev-env/report-*.json \| Select-Object -Last 1 \| Get-Content \| Test-Json -SchemaFile ai/schema.json` |
| 🔄 **Check phase ordering** | `./scripts/00-core-check.ps1; ./scripts/10-detect.ps1 -WhatIf` |
| 🔄 **Rebuild machines.json** | `Remove-Item ~/.dev-env/machines.json; ./bootstrap.ps1` |
| 🎯 **Switch profile** | `Set-Content ~/.dev-env/software-preferences.json '{"required":true,"recommended":false}'` |
| ✅ **Validate JSON report** | `Get-ChildItem ~/.dev-env/report-*.json \| Select-Object -Last 1 \| Get-Content \| Test-Json -SchemaFile ai/schema.json` |

---

## 🩺 Common Error Patterns

### Error: `Unable to find type [System.Collections.Generic.Dictionary`2]`
**Cause:** PowerShell 5.1 instead of 7
**Solution:**
```powershell
winget install Microsoft.PowerShell
# Nebo stáhni z https://github.com/PowerShell/PowerShell
```

### Error: `Access to the path 'C:\Program Files...' is denied`
**Cause:** Missing admin rights for symlink
**Solution:**
- Enable Developer Mode in Windows Settings
- OR run as admin: `Start-Process pwsh -Verb RunAs`
- OR script falls back to `Copy-Item` (check `link-configs.ps1`)

### Error: `git is not recognized`
**Cause:** Git not in PATH after installation
**Solution:**
```powershell
# Refresh PATH without restarting PowerShell
$env:Path = [Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [Environment]::GetEnvironmentVariable("Path","User")
git --version
```

### Error: `machines.json shows 'Gone: git, node'`
**Cause:** Corrupted history from buggy version
**Solution:**
```powershell
Remove-Item ~/.dev-env/machines.json -Verbose
./bootstrap.ps1  # Rebuilds clean history
```

### Error: `The request was aborted: Could not create SSL/TLS secure channel`
**Cause:** TLS 1.2 not enabled in PowerShell 5.1
**Solution:** Already in bootstrap.ps1:
```powershell
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
```

### Error: `OneDrive redirects system folders` v testech
**Cause:** Desktop/Documents jsou v OneDrivu
**Solution:**
```powershell
.\scripts\60-repair.ps1 -Force   # auto-fix (pokud KFM není aktivní)
# Nebo ručně: OneDrive → Nastavení → Zálohování → Spravovat zálohování
```

### Error: `PATH no duplicates (Cross:15)`
**Cause:** 15 cest je v System PATH i User PATH současně
**Solution:**
```powershell
.\scripts\60-repair.ps1 -Force   # odstraní z User PATH
```

---

## ✅ PR/Change Validation Checklist

### For NEW PowerShell scripts:
- [ ] Header pattern: `# === scripts/NAME.ps1 ===================`
- [ ] `[CmdletBinding(SupportsShouldProcess)]` if mutation
- [ ] `param([switch]$Force)` pattern
- [ ] Bilingual comments (English functional, Czech context)
- [ ] `Write-Host` s emoji indicators (✅/❌/⚠️)
- [ ] Error handling: `try/catch` for risky ops
- [ ] No aliases (`Get-ChildItem` not `ls`, `Where-Object` not `where`)
- [ ] `Join-Path` instead of string concatenation
- [ ] Tested with `-WhatIf` (no actual changes)
- [ ] Logs to `~/.dev-env/logs/`

### For PROFILE changes (`profiles/*.json`):
- [ ] Valid JSON (no trailing commas)
- [ ] `extends` field references valid base profile
- [ ] `identity` field exists (required by 70-test.ps1)
- [ ] `safeMode: true` for work/server profiles

### Security gate (MUST check):
- [ ] No `Invoke-Expression` on untrusted input
- [ ] No `Invoke-RestMethod` sending `machines.json` externally
- [ ] No hardcoded credentials or tokens
- [ ] `~/.ssh/`, `~/.dev-env/config/` in `.gitignore`
- [ ] Secrets section matches `profiles/base.json#/secrets`

---

## 📚 AI Context Loading Order

When starting work in this repo, load files in THIS order:

### LEVEL 1 — RULES (MUST read first)
1. `copilot-instructions.md` ← HARD rules, never violate
2. **AGENTS.md** (this file) ← navigation + decision tree

### LEVEL 2 — STRUCTURE (understand the system)
3. `manifest.json` ← authoritative file listing
4. `README.md` ← project overview + quick start
5. `docs/architecture.md` ← phase pipeline + flow

### LEVEL 3 — DOMAIN SPECIFIC (read as needed)
6. `ai/context.md` ← full AI lifecycle (16KB)
7. `ai/schema.json` ← report validation schema
8. `profiles/base.json` ← canonical config structure

### LEVEL 4 — SCRIPT CONTEXT (when editing)
9. `scripts/10-detect.ps1` ← understand detection logic
10. `scripts/60-repair.ps1` ← understand repair + rollback
11. `scripts/70-test.ps1` ← understand validation

### LEVEL 5 — CONVERSATION HISTORY
12. `ai/copilotchat.md` ← previous AI interactions

**Pro tip:** Use `@` mentions: `@AGENTS.md#AI-Decision-Tree`

## 💬 Example AI Responses

**User:** *"Nainstaluj mi to prostředí"*
**AI (good):**
> Nejprve spustím suchý běh, abych zjistil, co se stane:
> ```powershell
> $env:DEV_ENV_WHATIF='1'; irm https://raw.githubusercontent.com/doma77git/dev-env/master/bootstrap.ps1 | iex
> ```
> Vidím, že chybí git a PowerShell 7. Mám pokračovat s instalací?

**AI (bad):**
> Spouštím instalaci... *(spustí bootstrap bez -WhatIf — riziko!)*

---

**User:** *"Spadlo to na 50-setup-home.ps1"*
**AI (good):**
> Podívám se na logy:
> ```powershell
> Get-ChildItem ~/.dev-env/logs/ | Sort-Object LastWriteTime -Descending | Select-Object -First 1
> Get-Content (Get-ChildItem ~/.dev-env/logs/*.log | Sort-Object LastWriteTime -Descending | Select-Object -First 1).FullName | Select-Object -Last 50
> ```
> A zkontroluji stav pipeline:
> ```powershell
> Get-Content ~/.dev-env/last-repair-state.json 2>$null | ConvertFrom-Json
> ```

---

## 🏷️ Tag Schema for File Discovery

### By RISK LEVEL:
| Tag | Files | Action |
|-----|-------|--------|
| 🟢 **read-only** | `10-detect.ps1`, `70-test.ps1`, `ai/*`, `docs/*` | Safe to run anytime |
| 🟡 **with-whatif** | `50-setup-*.ps1`, `60-repair.ps1` | Run with `-WhatIf` first |
| 🔴 **mutation** | `60-repair.ps1` (Force), `50-setup-*.ps1` | Require `-Confirm` |
| ⚠️ **dangerous** | Scripts modifying `PATH` or OneDrive | Manual review required |

### By PURPOSE:
| Tag | Files |
|-----|-------|
| `detection` | `00-core-check.ps1`, `10-detect.ps1`, `40-profile.ps1` |
| `installation` | `20-install-software.ps1`, `50-setup-*.ps1` |
| `repair` | `60-repair.ps1`, `link-configs.ps1` |
| `validation` | `70-test.ps1`, `Confirm-Action.ps1`, `99-validate-bootstrap.ps1` |
| `orchestration` | `bootstrap.ps1`, `bootstrap.sh`, `00-menu.ps1` |
| `documentation` | `docs/*`, `ai/*.md`, `AGENTS.md`, `README.md` |

### By PROFILE:
| Tag | Files |
|-----|-------|
| `home` | `50-setup-home.ps1`, `profiles/home.json` |
| `work` | `50-setup-work.ps1`, `profiles/work.json` |
| `lab` | `50-setup-lab.ps1`, `profiles/lab.json` |
| `server` | `50-setup-server.ps1`, `profiles/server.json` |

---

## 🔒 HARD RULES (MUST follow — from copilot-instructions.md)

### Safety — NEVER auto-install
- **No package manager commands without user confirmation.**
- `safeMode` profiles (work, server) block installs entirely unless explicitly confirmed step-by-step.
- Phase `00-core-check.ps1` detects missing prerequisites — they NEVER run `winget install`.
- Phase 30 (`30-clone.ps1`) is always read-only.

### PowerShell scripts — header pattern
```powershell
#!/usr/bin/env pwsh
# === scripts/NAME.ps1 =========================================
# ROLE:   One-line description / český popis
# RUN:    ./scripts/NAME.ps1 [-Switch]
# INPUT:  dependencies
# OUTPUT: what it produces
# ==============================================================
```

### ShouldProcess contract
All mutation scripts must:
```powershell
[CmdletBinding(SupportsShouldProcess)]
param([switch]$Force)
```

### Secrets — NEVER commit
`~/.ssh/`, `machines.json`, `~/.dev-env/config/`, `~/.gitconfig.user`, `~/.npmrc`, `~/.aws/`, `~/.azure/`

---

## 📋 Phase Pipeline

```
00 → 30 → 10 → 20 → 40 → 50 → 60 → 70
```

| Phase | Script | Purpose |
|-------|--------|---------|
| 00 | `00-core-check.ps1` | PS7, git, connectivity — exit 1 if missing |
| 30 | `30-clone.ps1` | git clone/pull — always runs (read-only) |
| 10 | `10-detect.ps1` | Environment inventory — OS, PATH, OneDrive, tools |
| 20 | `20-report.ps1` | JSON report display + save |
| 40 | `40-profile.ps1` | Profile detection + identity |
| 50 | `50-setup-home.ps1` | Package install (ShouldProcess, logged) |
| 60 | `60-repair.ps1` | PATH, HOME, OneDrive repair (ShouldProcess, rollback) |
| 70 | `70-test.ps1` | 16 validation checks → exit 0=pass, 1=fail |

---

## 🧩 Project Structure

```
./
├── bootstrap.ps1          ← Windows orchestrator (one-liner)
├── bootstrap.sh           ← Linux/WSL orchestrator
├── AGENTS.md              ← Tento soubor — AI entry point
├── README.md              ← Dokumentace + Mermaid diagram
├── manifest.json          ← Authoritative metadata
├── copilot-instructions.md ← HARD agent rules
├── profiles/              ← JSON profily (base/home/work/lab/server)
├── scripts/               ← 14 PowerShell skriptů
├── configs/               ← Git + PowerShell configy
├── docs/                  ← Dokumentace (vč. security + troubleshooting)
├── ai/                    ← AI kontext + schema
├── menu/                  ← Interaktivní menu
├── data/                  ← Data exchange
└── .github/
    ├── instructions/      ← Language conventions
    ├── agents/            ← Custom AI agents
    ├── prompts/           ← Prompt templates
    └── workflows/         ← CI/CD
```

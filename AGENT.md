# Dev-Env Pipeline — AI Agent Instructions

> Auto-loaded by AI coding assistants (Copilot, Claude Code, Cursor, Codex, Reasonix)

## 🎯 Purpose

This repo automates Windows developer environment setup. AI agents use it to bootstrap, detect, install, and configure dev tools.

## 📁 Key Files

| File | Purpose |
|------|---------|
| `scripts/00-menu.ps1` | Main orchestrator with auto-countdown menu |
| `scripts/10-check-software.ps1` | Detect installed software (PATH + Program Files) |
| `scripts/20-install-software.ps1` | Winget install by category |
| `scripts/30-configure.ps1` | Dotfiles, git config, PowerShell profile |
| `scripts/50-setup-home.ps1` | Full home environment setup |
| `scripts/00-core-check.ps1` | Prerequisites (PowerShell, Git, network) |
| `scripts/60-repair.ps1` | PATH cleanup, OneDrive repair, rollback |
| `scripts/70-test.ps1` | 15 validation tests |
| `scripts/99-validate-bootstrap.ps1` | End-to-end pipeline validation |
| `~/.dev-env/software-preferences.json` | User category preferences |
| `~/.dev-env/software-inventory.json` | Installed software state |
| `~/.dev-env/workflow-state.json` | Pipeline progress state |
| `~/.dev-env/logs/` | All logs |

## 🚀 Quick Start for Agents

```powershell
# 1. Dry run (safe)
./scripts/00-menu.ps1 -WhatIf

# 2. Interactive menu with auto-countdown
./scripts/00-menu.ps1

# 3. Non-interactive (10s timeout → auto-install)
./scripts/00-menu.ps1 -TimeoutSeconds 1

# 4. Skip to specific phase
./scripts/20-install-software.ps1 -IncludeRequired -Force
```

## 📊 Software Categories

| Category | Icon | Apps | Auto-install |
|----------|------|------|--------------|
| Required | 🔴 | git, pwsh, wt | Always |
| Recommended | 🟡 | code, 7z, chrome, notepad++, gh, curl, reasonix | Default yes |
| Optional | 🟢 | nvim, docker, starship | Manual |
| Dev | 🔵 | node, python, vs2022, rider, postman | Manual |

## 🔧 Detection Rules

Each app is detected in this order:
1. `Get-Command` (PATH)
2. `Test-Path` (Program Files, LOCALAPPDATA)
3. Inventory cache (`software-inventory.json`)

## 🔐 Safety

- All modifications use `SupportsShouldProcess` (`-WhatIf`, `-Confirm`)
- Backup before repair: `Backup-Configuration` → `~/.dev-env/backups/<timestamp>/`
- Auto-rollback on failure: `Invoke-EnvironmentRepair` wrapper
- OneDrive KFM safety: blocks edits without `-Force`

## 🧪 Validation

Run `./scripts/99-validate-bootstrap.ps1` for full pipeline test:
```
00-core-check → 10-detect → 60-repair -WhatIf → 60-repair -Force → 70-test → 50-setup -WhatIf
```

## 🔗 Gists

| Gist | URL |
|------|-----|
| Bootstrap | `https://gist.github.com/doma77git/...` |
| Menu | `https://gist.github.com/doma77git/...` |
| Install | `https://gist.github.com/doma77git/...` |
| Setup | `https://gist.github.com/doma77git/...` |

## 🏗 State JSON format

```json
{
  "pipeline": {
    "phases": ["00", "10", "20", "30", "50", "60", "70"],
    "completed": ["00", "10"],
    "next": "20",
    "total": 7
  },
  "status": "in-progress"
}
```

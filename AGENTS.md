# dev-env — AGENTS.md

> Auto-loaded by AI coding assistants (Copilot, Claude Code, Cursor, Codex, etc.)
> This is the canonical entry point for all AI agents working in this repository.

---

## 🚦 Quick Orientation

**What is this?** A portable developer environment bootstrap system — one gist, one repo, all machines. Detects, reports, configures, repairs, and tests developer toolchains.

**Key files for AI agents:**
| File | Purpose |
|------|---------|
| `copilot-instructions.md` | HARD RULES + PREFERENCES for all agents |
| `ai/context.md` | Full AI lifecycle, decision tree, prompts (16KB) |
| `ai/copilotchat.md` | Copilot Chat conversation history & context |
| `ai/schema.json` | JSON Schema for detection reports |
| `manifest.json` | Authoritative metadata ($id, version, file listing) |
| `.github/instructions/` | Language-specific coding conventions |
| `.github/agents/` | Custom agent definitions |
| `.github/prompts/` | Reusable prompt templates |

## 🔒 HARD RULES (MUST follow — from `copilot-instructions.md`)

### Safety — NEVER auto-install
- **No package manager commands without user confirmation.**
- `safeMode` profiles (work, server) block installs entirely unless explicitly confirmed step-by-step.
- Phase `00-core-check.ps1` and `00-bootstrap-fallback.ps1` detect missing prerequisites — they NEVER run `winget install` or equivalent.
- Phase 30 (`30-clone.ps1`) is always read-only.

### PowerShell scripts — structure
Every `.ps1` script must follow the header pattern:
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
All mutation scripts (50-setup-*, 60-repair) must:
```powershell
[CmdletBinding(SupportsShouldProcess)]
param([switch]$Force)
```

### Secrets — NEVER commit
`~/.ssh/`, `machines.json`, `~/.dev-env/config/`, `~/.gitconfig.user`, `~/.npmrc`, `~/.aws/`, `~/.azure/`

## 📋 Phase Pipeline

```
00 → 30 → 10 → 20 → 40 → 50 → 60 → 70
```

| Phase | Script | Purpose |
|-------|--------|---------|
| 00 | `00-core-check.ps1` | PS7, git, connectivity — exit 1 if missing |
| 30 | `30-clone.ps1` | git clone/pull — always runs (read-only) |
| 10 | `10-detect.ps1` | Environment inventory — fingerprint, OS, tools |
| 20 | `20-report.ps1` | JSON report display + save |
| 40 | `40-profile.ps1` | Profile detection + identity + SSH + GPG |
| 50 | `50-setup-{profile}.ps1` | Package install (ShouldProcess, logged) |
| 60 | `60-repair.ps1` | PATH, HOME, OneDrive, SSH repair (ShouldProcess) |
| 70 | `70-test.ps1` | 15 validation checks → exit 0=pass, 1=fail |

## 🧩 Project Structure

```
.
├── bootstrap.ps1              ← Windows orchestrator
├── bootstrap.sh               ← Linux/WSL orchestrator
├── copilot-instructions.md    ← Agent rules (hard + preferences)
├── AGENTS.md                  ← This file — AI entry point
├── manifest.json              ← Authoritative metadata
├── index.html                 ← Persona-routed landing page
├── profiles/                  ← JSON profiles (base/home/work/lab/server)
├── scripts/                   ← PowerShell phase scripts
├── configs/                   ← Git + PowerShell configs
├── ai/                        ← AI context + schema
├── docs/                      ← Documentation
├── menu/                      ← Interactive terminal menu
├── data/                      ← Data exchange (.gitkeep only)
└── .github/
    ├── instructions/          ← Language conventions
    ├── agents/                ← Custom AI agents
    ├── prompts/               ← Prompt templates
    └── workflows/             ← CI/CD
```

## 🎯 Working with this repo

1. **Read `copilot-instructions.md` first** — it contains the hard rules and conventions
2. **Read `ai/context.md`** for the full lifecycle, decision tree, and prompt patterns
3. **Check `manifest.json`** for the authoritative file listing and version
4. **Use `.github/prompts/new-phase.prompt.md`** when creating new pipeline phase scripts
5. **Use the `ps-review` agent** (`.github/agents/ps-review.agent.md`) for PowerShell code review

## 📐 Conventions Summary

- **Bilingual**: English functional, Czech context — both in comments
- **No aliases**: Full cmdlet names (`Get-ChildItem`, not `ls`)
- **Join-Path**: No string concatenation for paths
- **Emoji indicators**: ✅ OK, ❌ FAIL, ⚠️ WARN
- **Phase headers**: `Write-Host ">>> PHASE XX — NAME" -ForegroundColor <color>`
- **Error handling**: `try/catch` for risky operations, `-ErrorAction SilentlyContinue` for optional checks

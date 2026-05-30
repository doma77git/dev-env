# dev-env — Agent Instructions

> Auto-loaded for all agents working in this repository.
> Covers PowerShell scripts, JSON profiles, and documentation conventions.

---

## HARD RULES (MUST follow)

### Safety — NEVER auto-install

- **No package manager commands without user confirmation.** Use `SupportsShouldProcess` in every mutation script. Always show `-WhatIf` output before `-Force`.
- **`safeMode` profiles (work, server) block installs entirely** unless explicitly confirmed step-by-step.
- **Core check scripts exit 1, never install.** Phase `00-core-check.ps1` and `00-bootstrap-fallback.ps1` detect missing prerequisites and recommend commands — they NEVER run `winget install` or equivalent.
- **Clone is read-only.** Phase 30 (`30-clone.ps1`) always runs, even in dry-run mode. It never mutates local state beyond `~/.dev-env/repo/`.

### PowerShell scripts — structure

Every `.ps1` script must follow this header pattern:

```powershell
#!/usr/bin/env pwsh
# === scripts/NAME.ps1 =========================================
# ROLE:   One-line English description / český popis
#         Detail line / detail
# RUN:    ./scripts/NAME.ps1 [-Switch]
# INPUT:  dependencies / inputs
# OUTPUT: what it produces
# ==============================================================
```

- Shebang line: `#!/usr/bin/env pwsh`
- Bilingual: English first, then Czech on the same or next line
- Phases use `Write-Host` with `-ForegroundColor` for structured output
- Phase header pattern: `Write-Host ">>> PHASE XX — NAME" -ForegroundColor <color>`
- Check pattern: `Write-Host "  ✅  OK"` / `Write-Host "  ❌  FAIL"` / `Write-Host "  ⚠  WARN"`

### ShouldProcess contract

All mutation scripts (50-setup-*, 60-repair) must:

```powershell
[CmdletBinding(SupportsShouldProcess)]
param([switch]$Force)
```

- Every state-changing operation wraps in `if ($PSCmdlet.ShouldProcess(...))`
- `-WhatIf` shows what WOULD happen without doing it
- `-Force` bypasses confirm dialogs (for CI/CD)
- No switch defaults to dry-run + `Confirm-Action` 10s timeout dialog

### JSON profiles — schema

- Every profile JSON inherits from `base.json` via `"extends": "base"` (except base itself)
- Required keys: `extends`, `identity` (with `git.name` + `git.email`), `proxy`, `safeMode` (boolean)
- Secrets list: canonical source is `profiles/base.json#/secrets` — all docs reference it, never duplicate
- `safeMode: true` means no automatic installs, everything requires explicit confirmation
- Profile auto-detection priority: Domain → OS caption → Manufacturer → Proxy → default home

### Secrets & .gitignore

- **Never commit**: `~/.ssh/`, `machines.json`, `~/.dev-env/config/`, `~/.gitconfig.user`, `~/.npmrc`, `~/.aws/`, `~/.azure/`
- `.gitignore` blocks: `data/*.json` (except `.gitkeep`), `*.log`, `.reasonix/`, design transcripts
- Transcript logs (`~/.dev-env/logs/setup-*.log`) are local-only, never committed

---

## PREFERENCES (SHOULD follow)

### Documentation style

- Markdown files use bilingual headers: `# 🏗️ English Title / Český název`
- Emoji prefixes for section icons (🏗️ architecture, 🔄 workflows, ⚠️ warnings)
- Tables for structured data (profiles, scripts, status, TODO)
- Mermaid diagrams for flows and architecture
- Edge cases documented in tables with `| Situation | Reaction |` format

### Phase pipeline order

The canonical pipeline order is: **00 → 30 → 10 → 20 → 40 → 50 → 60 → 70**

| Phase | Script | Purpose |
|---|---|---|
| 00 | `00-core-check.ps1` | PS7, git, connectivity — exit 1 if missing |
| 30 | `30-clone.ps1` | git clone/pull — always runs (read-only) |
| 10 | `10-detect.ps1` | Environment inventory — fingerprint, OS, tools, PATH |
| 20 | `20-report.ps1` | JSON report display + save |
| 40 | `40-profile.ps1` | Profile detection + identity + GitHub + SSH + GPG |
| 50 | `50-setup-{profile}.ps1` | Package install (ShouldProcess, transcript logged) |
| 60 | `60-repair.ps1` | PATH, HOME, OneDrive, SSH repair (ShouldProcess) |
| 70 | `70-test.ps1` | 15 validation checks → exit 0=pass, 1=fail |

### Naming conventions

- Script files: `NN-action.ps1` or `NN-action-profile.ps1` (e.g., `10-detect.ps1`, `50-setup-home.ps1`)
- Profile files: `name.json` in `profiles/` (e.g., `base.json`, `home.json`, `work.json`)
- Documentation: `topic.md` in `docs/` with bilingual title
- Config files: `tool/filename` in `configs/` (e.g., `git/.gitconfig`)

### Error handling

- `try/catch` around JSON parsing and tool detection
- Corrupted `machines.json` → graceful fallback to empty history
- Missing scripts → warn and skip, don't crash the pipeline
- Transcript logging wraps in `try/catch` — logging failure never blocks the pipeline

---

## PROJECT STRUCTURE

```
.
├── bootstrap.ps1              ← Windows orchestrator (00→30→10→20→40→50→60→70)
├── bootstrap.sh               ← Linux/WSL orchestrator (00→30→10→20→40→50)
├── README.md                  ← 6-persona routing, quickstart, TODO table
├── manifest.json              ← Authoritative metadata ($id, version, file listing)
├── index.html                 ← Local landing page (persona-routed: 👤/🤖/⚙️)
├── .gitignore                 ← Secrets + logs + transcripts excluded
├── profiles/
│   ├── base.json              ← Shared defaults (extends: null)
│   ├── home.json              ← Unrestricted personal PC
│   ├── work.json              ← Corporate PC (safeMode, proxy, GPG)
│   ├── lab.json               ← Lab VM (WSL, experimental)
│   └── server.json            ← Headless server (safeMode, no GUI)
├── scripts/
│   ├── 00-core-check.ps1      ← Prerequisites detection
│   ├── 00-bootstrap-fallback.ps1 ← PS5 fallback
│   ├── 10-detect.ps1          ← Environment inventory
│   ├── 20-report.ps1          ← Report display + JSON save
│   ├── 30-clone.ps1           ← Git clone/pull
│   ├── 40-profile.ps1         ← Profile detection + identity
│   ├── 50-setup-home.ps1      ← Home PC package install
│   ├── 50-setup-server.ps1    ← Server minimal toolchain
│   ├── 60-repair.ps1          ← PATH/HOME/OneDrive/SSH repair
│   ├── 70-test.ps1            ← 15 validation checks
│   ├── Confirm-Action.ps1     ← 10s timeout confirm dialog
│   ├── link-configs.ps1       ← Symlink configs from repo
│   └── undo-last.ps1          ← Rollback guidance from transcript
├── configs/
│   ├── git/.gitconfig         ← Shared git config
│   └── pwsh/profile.ps1       ← PowerShell profile
├── ai/
│   ├── context.md             ← Full AI context (16KB)
│   └── schema.json            ← JSON Schema for reports
├── docs/
│   ├── index.md               ← GitHub Pages landing
│   ├── architecture.md        ← Pipeline flow, layers, rollback
│   └── workflows.md           ← Step-by-step guides
├── menu/
│   └── menu.ps1               ← Interactive terminal menu
├── data/                      ← Data exchange (.gitkeep only)
└── .github/workflows/
    ├── ci.yml                 ← CI on push to master
    ├── pr.yml                 ← PR validation
    └── gist-sync.yml          ← Auto-update gist on release
```

---

## VERSION

Current: **v1.1.1** — see `manifest.json` for authoritative version.

## AI-READY FILES

This repository is AI-ready with the following convention files:
| File | Loaded by |
|------|-----------|
| `AGENTS.md` | All AI coding tools (Copilot, Claude Code, Cursor, Codex) |
| `copilot-instructions.md` | GitHub Copilot (root) |
| `.github/copilot-instructions.md` | GitHub Copilot (GitHub standard path) |
| `.cursorrules` | Cursor IDE |
| `.github/instructions/*.md` | Language-specific conventions |
| `.github/agents/*.md` | Custom AI agents |
| `.github/prompts/*.md` | Reusable prompt templates |
| `ai/context.md` | Full AI lifecycle reference |
| `ai/copilotchat.md` | Copilot Chat conversation context |

# dev-env — Reasonix working knowledge

## Stack

- **Language:** PowerShell 7+ (primary), Bash 4+ (Linux/WSL fallback)
- **Runtime:** `bootstrap.ps1` (Windows) / `bootstrap.sh` (Linux) — orchestrates pipeline phases
- **CI:** GitHub Actions — Windows (pwsh) + Linux (bash) matrix on push/PR
- **Schema:** `ai/schema.json` — JSON report contract; `profiles/*.json` — env definitions
- **Key deps:** git, pwsh, winget (Windows), curl (Linux) — checked by `00-core-check.ps1`

## Layout

| Path | Contents |
|------|----------|
| `scripts/` | 24 phase pipeline scripts — 00 (menu/core check) → 30 (clone/configure) → 10 (detect) → 20 (report/install) → 40 (profile) → 50 (setup dispatcher + per-profile) → 60 (repair) → 70 (test) + utilities (90–99, Confirm-Action, link-configs, undo-last) |
| `profiles/` | JSON env profiles: `base.json` (shared) → `home.json` / `work.json` / `lab.json` / `server.json` (extend base) |
| `configs/` | Symlink-friendly shared configs (`git/.gitconfig`, `pwsh/profile.ps1`) |
| `ai/` | Agent context docs (`context.md`, `copilotchat.md`) + `schema.json` |
| `docs/` | Human docs — architecture, workflows, troubleshooting, security |
| `.github/` | CI workflows (5), agent prompts, PS1 format hooks, copilot instructions |
| `menu/` | Legacy interactive terminal menu (`menu.ps1`); primary menu is `scripts/00-menu.ps1` |

## Commands

| Action | Command |
|--------|---------|
| Full bootstrap | `irm <gist>/bootstrap.ps1 \| iex` (Win) / `curl -fsSL <gist>/bootstrap.sh \| bash` (Linux) |
| Interactive menu | `./scripts/00-menu.ps1 [-WhatIf]` |
| Core check | `./scripts/00-core-check.ps1` / `./scripts/02-core-check.ps1 [-Force]` |
| Detect (read-only) | `./scripts/10-detect.ps1` |
| Install software | `./scripts/20-install-software.ps1 -IncludeRequired -IncludeRecommended [-Force]` |
| Clone/pull repo | `./scripts/30-clone.ps1` (read-only, always runs) |
| Apply dotfiles/configs | `./scripts/30-configure.ps1 [-Force]` |
| Detect profile | `./scripts/40-profile.ps1 [-Set home\|work\|lab\|server]` |
| Setup dispatcher | `./scripts/50-setup.ps1 [-WhatIf] [-Force] [-ProfileName home]` |
| Dry-run setup | `./scripts/50-setup-{profile}.ps1 -WhatIf` |
| Apply setup | `./scripts/50-setup-{profile}.ps1 -Force` |
| Dry-run repair | `./scripts/60-repair.ps1 -WhatIf` |
| Apply repair | `./scripts/60-repair.ps1 -Force` |
| Validate env | `./scripts/70-test.ps1` — 17 checks, exit 0 = pass |
| Windows Terminal profile | `./scripts/90-wt-profile.ps1 [-Force]` |
| HTML dashboard | `./scripts/95-dashboard.ps1 [-Output]` |
| End-to-end validation | `./scripts/99-validate-bootstrap.ps1 [-Quick]` |
| Report JSON | `./scripts/20-report.ps1` (save to ~/.dev-env/) |
| Link configs | `./scripts/link-configs.ps1 [-WhatIf] [-Force]` |
| Rollback guidance | `./scripts/undo-last.ps1 [-Pager]` |
| Legacy menu | `./menu/menu.ps1` |

## Conventions (visible in code)

- **Shebang:** Every `.ps1` starts with `#!/usr/bin/env pwsh`
- **Header block:** `# ROLE: / RUN: / INPUT: / OUTPUT:` in every script
- **ShouldProcess:** Every mutation script has `[CmdletBinding(SupportsShouldProcess)]` and `param([switch]$Force)`
- **Bilingual comments:** English (functional), Czech (context) — side by side
- **Output pattern:** Phase header `>>> PHASE XX — NAME` (green), checks use emoji prefixes (`✅` / `❌` / `⚠`)
- **Logging:** Every phase logs to `~/.dev-env/logs/<phase>-<timestamp>.log` via `Write-Log()` function
- **No aliases:** Full cmdlet names (`Get-ChildItem`, `Where-Object`, `Join-Path`), no `ls`/`where`/string concat
- **Profile JSON:** `extends` to base, `identity` (git name/email), `safeMode` (bool) fields mandatory
- **Git hooks:** `.github/hooks/` validate + auto-format `.ps1` files on write (PSScriptAnalyzer)
- **Secrets:** Canonical list in `profiles/base.json#/secrets` — all other docs reference it
- **Template:** `scripts/TEMPLATE.ps1` — copy as starting point for new phase scripts (logging, ShouldProcess, -Force included)

## Watch out for

- **`safeMode` profiles** (work, server) block all auto-installs — each item requires manual confirm, even with `-Force`
- **`machines.json` is LOCAL ONLY** — `~/.dev-env/machines.json` tracks detection history, never committed or synced
- **Phase 30 clone always runs**, even in dry-run (`-WhatIf`) mode — it's read-only to `~/.dev-env/repo/`
- **Phase 00 never installs** — `00-core-check.ps1` and `00-bootstrap-fallback.ps1` exit 1 on missing prerequisites
- **Phase ordering is non-numeric** — actual pipeline order: 00 → 30 → 10 → 20 → 40 → 50 → 60 → 70
- **Always `-WhatIf` before `-Force`** — skipping the dry-run is the most common mistake when editing setup/repair scripts
- **`scripts/00-menu.ps1` is the primary entry** — `bootstrap.ps1` delegates to it after clone/pull

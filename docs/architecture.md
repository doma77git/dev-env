# 🏗️ Architektura / Architecture

> Jak to funguje pod kapotou.

---

## Vrstvy / Layers

```
┌─────────────────────────────────────────┐
│  GIST (3 files)                          │  ← Entry point
│  bootstrap.ps1 (PS7 — orchestrátor)      │
│  00-bootstrap-fallback.ps1 (PS5)         │
│  bootstrap.sh (Linux/WSL)                │
├─────────────────────────────────────────┤
│  REPO (dev-env)                          │  ← Source of truth
│  Profily, skripty, konfigy, AI, docs.   │
├─────────────────────────────────────────┤
│  LOCAL (~/.dev-env/)                     │  ← Machine state
│  machines.json, reporty, klon repa.      │
├─────────────────────────────────────────┤
│  PAGES (doma77git.github.io/dev-env)    │  ← Documentation
│  docs/index.md → landing page.          │
└─────────────────────────────────────────┘
```

## Pipeline flow

```
bootstrap.ps1 (GIST)
  │
  ├─ 00. CORE CHECK ────────────────────
  │   scripts/00-core-check.ps1
  │   PS7, git, connectivity
  │   → exit 1 při chybě (nikdy neinstaluje)
  │
  ├─ 30. CLONE ─────────────────────────
  │   scripts/30-clone.ps1 (nebo inline)
  │   git clone/pull → ~/.dev-env/repo/
  │   VŽDY běží (read-only, ne mutace)
  │
  ├─ 10. DETECT ────────────────────────
  │   scripts/10-detect.ps1
  │   fingerprint, OS, 13 tools, PATH,
  │   OneDrive, corporate signals
  │
  ├─ 20. REPORT ────────────────────────
  │   scripts/20-report.ps1
  │   status (🔴new / 🟢same / 🟠os / 🟡tools)
  │   → ~/.dev-env/report-*.json
  │   → ~/.dev-env/machines.json (append)
  │
  ├─ 40. PROFILE ───────────────────────
  │   scripts/40-profile.ps1
  │   git identity, GitHub, SSH
  │   4.1 SYSTEM · 4.2 USER · 4.3 IDENTITIES · 4.4 TOOLS
  │   → ~/.dev-env/config/profile.json
  │
  ├─ 50. SETUP ─────────────────────────
  │   scripts/50-setup-{profile}.ps1
  │   [CmdletBinding(SupportsShouldProcess)]
  │   -WhatIf = suchý běh, -Confirm = ptát se,
  │   -Force = vše najednou
  │
  ├─ 60. REPAIR ────────────────────────
  │   scripts/60-repair.ps1
  │   PATH, HOME, OneDrive, SSH
  │   [CmdletBinding(SupportsShouldProcess)]
  │
  └─ 70. TEST ─────────────────────────
      scripts/70-test.ps1
      14 checks → pass/fail → exit code
      "testResult" in pipeline JSON
```

## Profily / Profiles

```
base.json  ←  všichni sdílí
  ├── home.json    ← osobní PC (volný režim, plná práva)
  ├── work.json    ← firemní PC (proxy, safeMode, omezení)
  ├── lab.json     ← testovací VM (WSL, scoop, experimenty)
  └── server.json  ← headless server (safeMode, bez GUI)
```

## Rozhodovací logika / Decision tree

```
Phase 00 — Core check:
  PS7+?  → continue
  PS5?   → "Install PS7 manually: winget install Microsoft.PowerShell" → exit 1
  git?   → continue
  no git → "Install git manually: winget install Git.Git" → exit 1
  github.com ping → OK/warning

Phase 30 — Clone:
  repo/.git exists → git pull
  broken repo      → Remove-Item scripts/ + git checkout HEAD -- scripts/
  no repo          → git clone -b master

Phase 40 — Profile detect priorita:
  1. saved profile (--Set)
  2. DOMAIN ≠ WORKGROUP              → 🏢 work (safeMode=true)
  3. OS caption = "Server"            → 🖳 server (safeMode=true)
  4. Manufacturer = VMware/VBox      → 🧪 lab
  5. Model = "Virtual"               → 🧪 lab
  6. proxy detected                  → 🏢 work (safeMode=true)
  7. else                            → 🏠 home

Phase 50-60 — ShouldProcess:
  No switch     → dry-run + confirm dialog (10s timeout)
  -WhatIf       → suchý běh (jen náhled)
  -Confirm      → ptát se u každé změny
  -Force        → vše najednou (CI/CD)

Identity priority (phase 40):
  saved ~/.dev-env/config/identity.json  → saved
  git config --global user.email         → git-config
  profile default (placeholder)         → placeholder
```

## Edge cases

| Situace | Reakce |
|---|---|
| PS5.1 | exit 1 + "winget install Microsoft.PowerShell" |
| Offline | warning, pokračuje (clone přeskočí) |
| Git missing | exit 1 + "winget install Git.Git" |
| Broken repo | Remove-Item + git clone |
| Headless (CI) | Confirm-Action timeout → skip |
| Corrupted machines.json | try/catch → prázdná historie |
| Symlink bez admin | fallback Copy-Item |
| OneDrive redirect | repair varuje, neopravuje automaticky |

## TODO / Roadmap

| Stav | Položka |
|---|---|
| ✅ | Fáze 00→30→10→20→40→50→60→70 |
| ✅ | ShouldProcess na setup/repair |
| ✅ | Clone vždy běží (read-only, i v dry-run) |
| ✅ | 00-core-check.ps1 — žádná instalace |
| ✅ | 00-bootstrap-fallback.ps1 — detect→recommend→exit |
| ✅ | Confirm-Action 10s timeout + headless |
| 🟠 | Linux/WSL bootstrap.sh — parity s .ps1 |
| 🟠 | Interaktivní režim v setup (výběr packages) |
| 🟠 | Server setup script (scripts/50-setup-server.ps1) |

---

## Verzování / Versioning

| Vrstva | Jak |
|---|---|
| Gist | Manuálně — `gh gist edit` při změně |
| Repo | `git push/pull` |
| machines.json | Nikdy — lokální |
| Reporty | Append-only — `~/.dev-env/report-*.json` |

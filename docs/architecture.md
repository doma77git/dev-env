# 🏗️ Architektura / Architecture

> Jak to funguje pod kapotou.

---

## Vrstvy / Layers

```
┌─────────────────────────────────────────┐
│  GIST (3 files)                         │  ← Entry point
│  bootstrap.ps1 (PS7)                    │
│  00-bootstrap-fallback.ps1 (PS5)        │
│  bootstrap.sh (Linux/WSL)               │
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
  ├─ 00. BOOTSTRAP ──────────────────────
  │   gist URL → hand-off
  │
  ├─ 01. PROFILE (inline cheap) ──────────
  │   domain, OS caption, manufacturer
  │   → 🏠 home / 🏢 work / 🖳 server / 🧪 lab
  │   → safeMode (corp/server = no auto-install)
  │
  ├─ 02. CORE CHECK ──────────────────────
  │   PS version → PS5? loop try install
  │   (winget → direct MSI → spawn pwsh)
  │   Shell, terminal (wt), installer
  │
  ├─ 10. DETECT ─────────────────────────
  │   fingerprint, OS, 13 tools, PATH,
  │   OneDrive, corporate signals
  │   → JSON report
  │
  ├─ 15. REPORT ─────────────────────────
  │   status (🔴new / 🟢same / 🟠os / 🟡tools)
  │   → ~/.dev-env/report-*.json
  │   → ~/.dev-env/machines.json (append)
  │
  ├─ 20. CLONE ──────────────────────────
  │   git exists? → clone/pull → ~/.dev-env/repo/
  │   git missing? → REMOTE FALLBACK
  │     (raw.githubusercontent.com)
  │
  ├─ 30. PROFILE IDENTITY ───────────────
  │   scripts/40-profile.ps1
  │   git identity, GitHub, SSH
  │   4.1 SYSTEM · 4.2 USER · 4.3 IDENTITIES · 4.4 TOOLS
  │   → ~/.dev-env/config/profile.json
  │
  ├─ 40. ESSENTIALS ─────────────────────
  │   🖥️ TERMINAL: wt + pwsh
  │   HOME: dry-run → confirm (5s) → install
  │   CORP: report only, skip
  │
  ├─ 50. CATEGORIES ─────────────────────
  │   🌐 BROWSER · 🤖 AI · 📝 EDITORS · 
  │   🔧 PROJECT · 📦 UTILS
  │   HOME: recommended + optional → confirm
  │   CORP: report only
  │
  ├─ 60. REPAIR ─────────────────────────
  │   PATH duplicates, HOME, OneDrive, SSH
  │   scripts/60-repair.ps1
  │
  └─ 70. TEST ──────────────────────────
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
  └── server.json  ← headless server (safeMode, bez GUI, nový!)
```

## Rozhodovací logika / Decision tree

```
Phase 01 — Profile detect priorita:
  1. saved profile (--Set)
  2. DOMAIN ≠ WORKGROUP              → 🏢 work (safeMode=true)
  3. OS caption = "Server"            → 🖳 server (safeMode=true)
  4. Manufacturer = VMware/VBox      → 🧪 lab
  5. Model = "Virtual"               → 🧪 lab
  6. proxy detected                  → 🏢 work (safeMode=true)
  7. else                            → 🏠 home

Phase 02 — Core check:
  PS7?  → continue
  PS5?  → safeMode? → skip → "install manually"
        → home? → try winget → try MSI → spawn pwsh window

Phase 30 — Identity priority:
  saved ~/.dev-env/config/identity.json  → saved
  git config --global user.email         → git-config
  profile default (placeholder)         → placeholder
```

## TODO / Roadmap

| Stav | Položka |
|---|---|
| ✅ | Phase numbering 00–70 (step 10) |
| ✅ | 50-setup-home categories: 🖥️🌐🤖📝🔧📦 |
| ✅ | 50-setup-work — firemní instalace |
| ✅ | 50-setup-lab — testovací VM |
| ✅ | Deep merge v 40-profile.ps1 |
| ✅ | 00-bootstrap-fallback.ps1 — PS5 fallback |
| ✅ | Confirm-Action + headless detection |
| ✅ | Remote fallback (raw.githubusercontent.com) |
| ✅ | Server profile detection |
| 🟠 | Split 50-setup-home into 40-essentials + 50-categories |
| 🟠 | Pipeline JSON completed tracking for 01,02,15 |
| 🟠 | Server setup script (scripts/50-setup-server.ps1) |

---

## Verzování / Versioning

| Vrstva | Jak |
|---|---|
| Gist | Manuálně — `gh gist edit` při změně |
| Repo | `git push/pull` |
| machines.json | Nikdy — lokální |
| Reporty | Append-only — `~/.dev-env/report-*.json` |

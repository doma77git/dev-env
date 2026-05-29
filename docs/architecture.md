# 🏗️ Architektura / Architecture

> Jak to funguje pod kapotou.

---

## Vrstvy / Layers

```
┌─────────────────────────────────────────┐
│  GIST (bootstrap.ps1 + bootstrap.sh)    │  ← Entry point
│  Neměnný. Self-contained detect.        │
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

## Tok dat / Data flow

```
bootstrap.ps1 (GIST)
  │
  ├─ 00. BOOTSTRAP ──────────────────────
  │   gist URL, hand-off
  │
  ├─ 10. DETECT ─────────────────────────
  │   fingerprint, OS, tools, PATH,
  │   OneDrive, corporate
  │   → JSON report
  │
  ├─ 20. OUTPUT ─────────────────────────
  │   status + JSON → konzole
  │   → ~/.dev-env/report-*.json
  │   → ~/.dev-env/machines.json (append)
  │
  ├─ 30. CLONE (if git exists) ──────────
  │   git clone → ~/.dev-env/repo/
  │
  └─ 40. PROFILE ────────────────────────
      scripts/40-profile.ps1
      → domain, proxy, manufacturer
      → home | work | lab
      → ~/.dev-env/config/profile.json
```

## Profily / Profiles

```
base.json  ←  všichni sdílí
  ├── home.json    ← osobní PC (volný režim)
  ├── work.json    ← firemní PC (proxy, GPO, omezení)
  └── lab.json     ← testovací VM (WSL, experimenty)
```

## Rozhodovací logika / Decision tree

```
$env:USERDOMAIN
  ├── ≠ "WORKGROUP" (doména)      →  work
  ├── manufacturer = VMware/VB    →  lab
  ├── proxy existuje              →  work (VPN?)
  └── jinak                       →  home

Uživatel může přepsat:  -Set home|work|lab
```

## TODO / Roadmap

| Stav | Položka |
|---|---|
| ✅ | Phase numbering 00–70 (step 10) |
| ✅ | `50-setup-work.ps1` — firemní instalace |
| ✅ | `50-setup-lab.ps1` — testovací VM |
| ✅ | Deep merge v `40-profile.ps1` |
| ✅ | `00-bootstrap-fallback.ps1` — PS5 fallback |

---

## Verzování / Versioning

| Vrstva | Jak |
|---|---|
| Gist | Manuálně — kopie z repa při změně |
| Repo | `git push/pull` |
| machines.json | Nikdy — lokální |
| Reporty | Append-only — `~/.dev-env/report-*.json` |

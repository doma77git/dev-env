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
  ├─ 1. DETECT ──────────────────────────
  │   fingerprint, OS, tools, PATH,
  │   OneDrive, corporate
  │   → JSON report
  │
  ├─ 2. OUTPUT ──────────────────────────
  │   status + JSON → konzole
  │   → ~/.dev-env/report-*.json
  │   → ~/.dev-env/machines.json (append)
  │
  ├─ 3. CLONE (if git exists) ───────────
  │   git clone → ~/.dev-env/repo/
  │
  └─ 4. PROFILE ─────────────────────────
      scripts/profile.ps1
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

## Verzování / Versioning

| Vrstva | Jak |
|---|---|
| Gist | Manuálně — kopie z repa při změně |
| Repo | `git push/pull` |
| machines.json | Nikdy — lokální |
| Reporty | Append-only — `~/.dev-env/report-*.json` |

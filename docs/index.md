# 🧰 dev-env

> One command. Full inventory. All machines.  
> Jeden příkaz. Plná inventura. Všechny stroje.

---

## ⚠️ Než začneš

- **PowerShell 7+** — `bootstrap.ps1` vyžaduje PS7. Na PS5 spusť `00-bootstrap-fallback.ps1` (nainstaluje pwsh+wt+git)
- **-WhatIf před -Force** — všechny skripty podporují suchý běh. Vždycky nejdřív `-WhatIf`.
- **Firemní stroj** — `safeMode` se automaticky detekuje. Nikdy nic neinstaluje bez potvrzení.
- **Server / headless** — detekuje se podle OS caption. safeMode = true.

---

## ⚡ Quickstart / Rychlý start

```powershell
# Windows PS7 — doporučeno
irm https://gist.github.com/doma77git/2f489d9ce5e7e0ff75b17cbe8011bbb5/raw/bootstrap.ps1 | iex

# Windows PS5 — fallback (nainstaluje pwsh+git, spawnuje PS7)
powershell -NoProfile -Command "irm https://gist.githubusercontent.com/doma77git/2f489d9ce5e7e0ff75b17cbe8011bbb5/raw/00-bootstrap-fallback.ps1?v=1 | iex"
```

```bash
# Linux / WSL
curl -fsSL https://gist.github.com/doma77git/2f489d9ce5e7e0ff75b17cbe8011bbb5/raw/bootstrap.sh | bash
```

---

## 🔄 Jak to funguje

```
irm | iex
  ├─ PS7 ──▶ 00→01→02→10→15→20→30→40→50→60→70
  └─ PS5 ──▶ 00-bootstrap-fallback → pwsh+git ↗
```

| Fáze | Co se děje |
|---|---|
| **00. Bootstrap** | gist URL, hand-off |
| **01. Profile** | Corp/home/server/lab → safeMode |
| **02. Core check** | PS version, shell, terminal, installer (PS7 loop) |
| **10. Detect** | Fingerprint, OS, 13 tools, PATH, OneDrive, corporate |
| **15. Report** | JSON → `~/.dev-env/` — for AI + human |
| **20. Clone** | git clone / remote fallback |
| **30. Profile** | Home/work/lab/server identity, GitHub, SSH |
| **40. Essentials** | 🖥️ wt + pwsh (confirm 5s) |
| **50. Categories** | 🌐🤖📝🔧📦 recommended + optional |
| **60. Repair** | PATH duplicates, HOME, OneDrive |
| **70. Test** | 14 checks → pass/fail → exit code |

---

## 👤 Profily

| Profil | Spouští se když | safeMode |
|---|---|---|
| 🏠 **home** | WORKGROUP, žádný proxy, ne VM | ❌ |
| 🏢 **work** | Doména (≠ WORKGROUP), proxy | ✅ |
| 🧪 **lab** | VMware/VirtualBox / Virtuální model | ❌ |
| 🖳 **server** | OS caption "Server" | ✅ |

---

## 📂 Adresářová struktura

```
~/.dev-env/
├── machines.json           ← historie detekcí (nikdy nesyncovat)
├── report-*.json           ← poslední report
├── config/                 ← lokální přepsání profilu
└── repo/                   ← git clone repozitáře
    ├── bootstrap.ps1
    ├── scripts/
    │   ├── 00-bootstrap-fallback.ps1  ← PS5 fallback
    │   ├── 40-profile.ps1     ← detekce profilu
    │   ├── 50-setup-home.ps1  ← instalace pro doma
    │   ├── 50-setup-lab.ps1   ← VM
    │   ├── 50-setup-work.ps1  ← firemní
    │   ├── 60-repair.ps1      ← opravy
    │   ├── 70-test.ps1        ← validace
    │   ├── Confirm-Action.ps1 ← potvrzovací dialog (5s timeout)
    │   └── link-configs.ps1   ← symlinky konfigů
    ├── profiles/             ← JSON definice profilů
    ├── configs/              ← verzované konfigy
    ├── ai/                   ← pro AI agenty
    ├── menu/menu.ps1         ← interaktivní menu
    └── docs/                 ← dokumentace
```

```
Doporučená struktura projektů:
~/dev/projects/
├── osobni/                 ← osobní projekty
├── ppg/                    ← firemní projekty
└── lab/                    ← experimenty
```

---

## 🧪 Skripty

| Skript | Spuštění | Co dělá |
|---|---|---|
| `scripts/40-profile.ps1` | `./40-profile.ps1` | Detekce profilu |
| `scripts/50-setup-home.ps1` | `./50-setup-home.ps1 -WhatIf` | Instalace kategorie (🖥️🌐🤖📝🔧📦) |
| `scripts/60-repair.ps1` | `./60-repair.ps1 -WhatIf` | Opravy PATH, HOME, OneDrive |
| `scripts/70-test.ps1` | `./70-test.ps1` | 14 kontrol |
| `scripts/link-configs.ps1` | `./link-configs.ps1 -WhatIf` | Symlinky konfigů |
| `scripts/Confirm-Action.ps1` | dot-source | Interaktivní potvrzení (5s timeout) |
| `menu/menu.ps1` | `./menu.ps1` | Interaktivní menu |

---

## 🗺️ Odkazy

| Kam | URL |
|---|---|
| 🔩 Repo | [github.com/doma77git/dev-env](https://github.com/doma77git/dev-env) |
| ⚡ Gist | `https://gist.github.com/doma77git/2f489d9ce5e7e0ff75b17cbe8011bbb5` |
| 🧠 Manifest | [manifest.json](../manifest.json) |
| 📐 Schema | [ai/schema.json](../ai/schema.json) |
| 🏗️ Architektura | [docs/architecture.md](architecture.md) |
| 🔄 Workflow | [docs/workflows.md](workflows.md) |

---

## ⚠️ Co se nikdy nesyncuje

| Složka | Důvod |
|---|---|
| `~/.ssh/` | SSH klíče |
| `~/.dev-env/machines.json` | Lokální historie |
| `~/.dev-env/config/` | Lokální přepsání |
| `~/.gitconfig.user` | Osobní identita |
| `~/.npmrc`, `~/.aws/`, `~/.azure/` | Tokeny |

---

## 🧠 Pro AI agenty

- **Manifest**: [`manifest.json`](../manifest.json) — autoritativní popis celého projektu
- **Schema**: [`ai/schema.json`](../ai/schema.json) — struktura reportu
- **Profily**: [`profiles/*.json`](../profiles/) — definice prostředí

---

*dev-env v1.0.0 · 2026-05-30 · [manifest.json](../manifest.json)*

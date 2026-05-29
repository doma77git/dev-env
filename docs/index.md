# 🧰 dev-env

> One command. Full inventory. All machines.  
> Jeden příkaz. Plná inventura. Všechny stroje.

---

## ⚠️ Než začneš

- **PowerShell 7+** — `bootstrap.ps1` vyžaduje PS7. Na PS5 spusť `00-bootstrap-fallback.ps1` (nainstaluje pwsh+wt+git)
- **Git** — pro clone repa. Bez něj detekce funguje, ale `scripts/` nebudou dostupné.
- **-WhatIf před -Force** — všechny skripty podporují suchý běh. Vždycky nejdřív `-WhatIf`.
- **Firemní stroj** — `winget` a `irm` můžou být blokované. Bootstrap to detekuje → `work` profil.

---

## ⚡ Quickstart / Rychlý start

```powershell
# Windows
irm https://gist.github.com/doma77git/2f489d9ce5e7e0ff75b17cbe8011bbb5/raw/bootstrap.ps1 | iex
```

```bash
# Linux / WSL
curl -fsSL https://gist.github.com/doma77git/2f489d9ce5e7e0ff75b17cbe8011bbb5/raw/bootstrap.sh | bash
```

---

## 🔄 Jak to funguje

```
irm | iex
  ├─ PS7? ──ano──▶ PHASE 00 → 10 → 20 → 30 → 40 → 50
  └─ PS5? ──────▶ 00-bootstrap-fallback.ps1 → pwsh+wt+git → pwsh → hlavní pipeline
```

| Fáze | Co se děje |
|---|---|
| **00. Bootstrap** | Entry point, gist URL |
| **10. Detect** | Fingerprint stroje, OS, nástroje, PATH, OneDrive, firemní signály |
| **20. Report** | JSON → `~/.dev-env/` — pro AI i člověka |
| **30. Clone** | `git clone` repa → `~/.dev-env/repo/` |
| **40. Profile** | Auto-detekce: 🏠 home / 🏢 work / 🧪 lab |
| **50. Setup** | Instalace balíčků, vytvoření složek, symlinky |
| **60. Repair** | Opravy PATH, HOME, OneDrive |
| **70. Test** | Validace — 14 kontrol — pass/fail |
| **Menu** | Interaktivní rozcestník |

---

## 👤 Profily

| Profil | Spouští se když |
|---|---|
| 🏠 **home** | Domácí PC — `WORKGROUP`, žádný proxy, plná práva |
| 🏢 **work** | Firemní PC — doménový účet, proxy, omezení |
| 🧪 **lab** | Testovací VM — VMware/VirtualBox, experimenty |

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
    │   └── link-configs.ps1   ← symlinky konfigů
    ├── profiles/           ← JSON definice profilů
    ├── configs/            ← verzované konfigy
    ├── ai/                 ← pro AI agenty
    ├── menu/menu.ps1       ← interaktivní menu
    └── docs/               ← dokumentace
```

```
Doporučená struktura projektů:
~/dev/projects/
├── osobni/                 ← osobní projekty (git: jan@novak.cz)
├── ppg/                    ← firemní projekty (git: jan.novak@ppg.com)
└── lab/                    ← experimenty (git: jan+lab@novak.cz)

~/Documents/
├── downloads/
│   ├── _temp/              ← dočasné (mazat)
│   └── keep/               ← trvalé
└── docs/
    ├── navody/             ← návody, reference
    ├── architektura/       ← UML, BPMN diagramy
    └── faktury/            ← faktury, smlouvy

~/Documents/chat-exports/   ← AI konverzace, exporty
```

---

## 🧪 Skripty

| Skript | Spuštění | Co dělá |
|---|---|---|
| `scripts/40-profile.ps1` | `./40-profile.ps1` | Detekce profilu |
| `scripts/50-setup-home.ps1` | `./50-setup-home.ps1 -WhatIf` | Instalace pro doma |
| `scripts/60-repair.ps1` | `./60-repair.ps1 -WhatIf` | Opravy |
| `scripts/70-test.ps1` | `./70-test.ps1` | 14 kontrol |
| `scripts/link-configs.ps1` | `./link-configs.ps1 -WhatIf` | Symlinky konfigů |
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

## 🟠 TODO

| Co | Stav |
|---|---|
| `scripts/50-setup-work.ps1` | Firemní instalace (proxy, VPN) |
| `scripts/50-setup-lab.ps1` | Testovací VM (WSL, scoop) |
| Deep merge v 40-profile.ps1 | ✅ Hotovo |

---

## 🧠 Pro AI agenty

- **Manifest**: [`manifest.json`](../manifest.json) — autoritativní popis celého projektu
- **Schema**: [`ai/schema.json`](../ai/schema.json) — struktura reportu
- **Profily**: [`profiles/*.json`](../profiles/) — definice prostředí

---

*dev-env v1.0.0 · 2026-05-29 · [manifest.json](../manifest.json)*

# 🔒 Security — Dev-Env Pipeline

## 🔐 Co chráníme

| Data | Kde jsou | Riziko |
|------|----------|--------|
| SSH privátní klíče | `~/.ssh/id_*` | 🔴 Únik = kompromitace serverů |
| Git identity | `~/.gitconfig`, `~/.dev-env/config/identity.json` | 🟡 Krádež identity |
| Tokeny | `~/.npmrc`, `~/.aws/`, `~/.azure/` | 🔴 Přístup k cloudům |
| Machine fingerprint | `~/.dev-env/machines.json` | 🟡 Historie strojů |

## 🚫 Nikdy necommitovat

Tyto cesty jsou v `.gitignore` a pipeline je chrání:

```
~/.ssh/                    — SSH privátní klíče
~/.dev-env/config/         — Lokální přepisy profilů
~/.dev-env/machines.json   — Historie detekcí
~/.gitconfig.user          — Osobní git identita
~/.npmrc                   — NPM registry tokeny
~/.aws/                    — AWS credentials
~/.azure/                  — Azure credentials
```

## 🛡️ Bezpečnostní mechanismy

### 1. `-WhatIf` a `-Confirm`

**Všechny** destruktivní skripty podporují:
```powershell
.\scripts\60-repair.ps1 -WhatIf    # Ukáže co by se stalo
.\scripts\60-repair.ps1 -Confirm   # Ptá se na každý krok
.\scripts\50-setup-home.ps1 -WhatIf
```

### 2. `SupportsShouldProcess`

Každý skript, který modifikuje systém, má:
```powershell
[CmdletBinding(SupportsShouldProcess)]
param([switch]$Force)
```

### 3. Backup před změnou

`60-repair.ps1` automaticky volá `Backup-Configuration`:
```
~/.dev-env/backups/20260531-015930/
  ├── .gitconfig
  ├── profile.ps1
  ├── ssh/*.pub
  ├── path-snapshot.json
  ├── onedrive-registry.reg
  └── RESTORE.ps1
```

### 4. Auto-rollback při selhání

`Invoke-EnvironmentRepair` wrapper:
```
🔧  PATH dedup ... FAIL
🔄  Spouštím automatický rollback ...
    RESTORE.ps1 → OK
✅  Rollback dokončen
```

### 5. Žádné admin operace naslepo

- Pipeline **neinstaluje** bez detekce (nejdřív `10-detect.ps1`)
- Registry změny pouze v `HKCU:` (uživatelský kontext)
- Nikdy `HKLM:` bez explicitního `-Force`

### 6. KFM safety

Pokud je OneDrive Known Folder Move aktivní, pipeline blokuje změny:
```
❌ KRITICKÉ: OneDrive KFM je aktivní
    Bez -Force nelze bezpečně upravit OneDrive přesměrování.
```

## 📝 Doporučené postupy

```powershell
# 1. VŽDY začínejte suchým během
.\bootstrap.ps1 -WhatIf

# 2. Pro citlivé operace použijte -Confirm
.\scripts\60-repair.ps1 -Confirm

# 3. Pravidelně kontrolujte logy
Get-ChildItem ~/.dev-env/logs/ | Sort-Object LastWriteTime -Descending | Select-Object -First 5

# 4. Zálohy mažte až po ověření stability
Get-ChildItem ~/.dev-env/backups/ | Sort-Object Name -Descending | Select-Object -First 1
```

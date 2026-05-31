# 🔧 Troubleshooting — Dev-Env Pipeline

## 🚨 Časté problémy a řešení

### 1. Pipeline hlásí `❌ OneDrive not redirecting system folders`

**Příčina:** Systémové složky (Desktop, Documents, Pictures, Music, Videos) jsou přesměrovány do OneDrivu.

**Řešení:**
```powershell
# Automatická oprava (pokud KFM není aktivní)
.\scripts\60-repair.ps1 -Force

# Ručně: OneDrive → Nastavení → Zálohování → Spravovat zálohování
# → Kliknout na složku → Zastavit zálohování
```

### 2. `❌ PATH no duplicates` — duplicity v PATH

**Příčina:** Stejná cesta je v System PATH i User PATH.

**Řešení:**
```powershell
.\scripts\60-repair.ps1 -Force
# Automaticky odstraní duplicity z User PATH
```

### 3. `❌ Profile JSONs valid`

**Příčina:** `profiles/base.json` chybí `identity` field.

**Řešení:**
```powershell
git pull origin master   # Opraveno v nejnovější verzi
```

### 4. `🔐 KFM safety: ACTIVE` blokuje opravy

**Příčina:** OneDrive Known Folder Move je aktivní (`IsKFMEnabled=1`).

**Řešení:**
```
OneDrive → Nastavení → Zálohování → Spravovat zálohování
→ Zastavit zálohování pro všechny složky
→ Pak spustit: .\scripts\60-repair.ps1 -Force
```

### 5. Aplikace není detekována (zobrazuje ☐ místo ✅)

**Příčina:** Aplikace je nainstalovaná, ale není v PATH a není v `knownPaths` mapě.

**Řešení:** Přidejte cestu do `Test-AppInstalled` v `scripts/00-menu.ps1`:
```powershell
$knownPaths = @{
    "moje-app" = @("$env:ProgramFiles\MojeApp\app.exe", "$env:LOCALAPPDATA\MojeApp\app.exe")
}
```

### 6. `winget install` selhává

**Příčina:** Různé — chyba sítě, chybějící source agreements, blokovaný instalační program.

**Řešení:**
```powershell
# Ruční instalace konkrétního balíčku
winget install Git.Git --accept-package-agreements

# Reset winget cache
winget source reset --force
```

### 7. Změny se neprojevují po `60-repair.ps1 -Force`

**Příčina:** `[Environment]::GetFolderPath()` cachuje hodnoty do odhlášení.

**Řešení:**
```powershell
# Odhlásit a přihlásit, nebo restartovat Explorer
taskkill /f /im explorer.exe
start explorer.exe
```

### 8. `git push` selhává — "no authentication"

**Příčina:** Není nastavený GitHub token nebo SSH klíč.

**Řešení:**
```powershell
# Vytvořit SSH klíč
ssh-keygen -t ed25519 -C "$env:USERNAME@$env:COMPUTERNAME"
# Přidat do GitHub: https://github.com/settings/keys
```

## 📊 Diagnostika

### Rychlý health check
```powershell
.\scripts\70-test.ps1
```

### Kompletní pipeline test
```powershell
.\scripts\99-validate-bootstrap.ps1
```

### Logy
```powershell
Get-ChildItem ~/.dev-env/logs/ | Sort-Object LastWriteTime -Descending | Select-Object -First 5
Get-Content (Get-ChildItem ~/.dev-env/logs/*.log | Sort-Object LastWriteTime -Descending | Select-Object -First 1).FullName
```

### Stav pipeline
```powershell
Get-Content ~/.dev-env/last-repair-state.json | ConvertFrom-Json
```

## 🆘 Kdy spustit co

```powershell
# Jen detekce (bezpečné, nic nemění)
.\scripts\10-detect.ps1

# Jen testy (bezpečné)
.\scripts\70-test.ps1

# Suchý běh oprav
.\scripts\60-repair.ps1 -WhatIf

# Skutečná oprava
.\scripts\60-repair.ps1 -Force

# Kompletní validace
.\scripts\99-validate-bootstrap.ps1
```

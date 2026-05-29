# 🔄 Workflow / Pracovní postupy

---

## 🆕 Nový stroj / New machine

```powershell
# 1. Bootstrap
irm https://gist.github.com/doma77git/2f489d9ce5e7e0ff75b17cbe8011bbb5/raw/bootstrap.ps1 | iex

# 2. Zkontroluj profil
cd ~/.dev-env/repo
./scripts/profile.ps1

# 3. Suchý běh instalace
./scripts/setup-home.ps1 -WhatIf

# 4. Instaluj
./scripts/setup-home.ps1 -Force

# 5. Oprav
./scripts/repair.ps1 -WhatIf
./scripts/repair.ps1 -Force

# 6. Otestuj
./scripts/test.ps1
```

---

## 🔁 Existující stroj / Existing machine

```powershell
# 1. Bootstrap (detekuje změny)
irm https://gist.github.com/doma77git/2f489d9ce5e7e0ff75b17cbe8011bbb5/raw/bootstrap.ps1 | iex

# 2. Menu → pull + volby
cd ~/.dev-env/repo
./menu/menu.ps1
```

---

## 🔄 Po reinstalaci / After reinstall

```powershell
# Bootstrap detekuje os-changed
irm https://gist.github.com/doma77git/2f489d9ce5e7e0ff75b17cbe8011bbb5/raw/bootstrap.ps1 | iex

# Plná instalace
cd ~/.dev-env/repo
./scripts/setup-home.ps1 -Force
./scripts/repair.ps1 -Force
./scripts/link-configs.ps1 -Force
./scripts/test.ps1
```

---

## 🏢 Firemní stroj / Corporate machine

```powershell
# 1. Bootstrap
irm https://gist.github.com/doma77git/2f489d9ce5e7e0ff75b17cbe8011bbb5/raw/bootstrap.ps1 | iex

# 2. Profil → work (auto)
cd ~/.dev-env/repo
./scripts/profile.ps1

# 3. Review omezení
#    - no winget → manuální instalace
#    - proxy → nastavit http_proxy
#    - execution policy → RemoteSigned

# 4. Test
./scripts/test.ps1
```

---

## 🧪 Lab VM / Test VM

```powershell
# Bootstrap detekuje VMware/VirtualBox → lab
irm https://gist.github.com/doma77git/2f489d9ce5e7e0ff75b17cbe8011bbb5/raw/bootstrap.ps1 | iex

# WSL, scoop, experimenty
cd ~/.dev-env/repo
./scripts/profile.ps1
```

---

## 🔄 Sync / Synchronizace

```powershell
# Pull repa
cd ~/.dev-env/repo && git pull

# Push změny
cd ~/.dev-env/repo
git add -A
git commit -m "update"
git push

# Nebo přes menu:
./menu/menu.ps1 → [6] Sync
```

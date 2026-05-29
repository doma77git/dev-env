### You

Potřebuji vybudovat čisté, přenositelné vývojářské prostředí na Windows.  
Nemám zatím žádný fungující systém. Tvým úkolem je provést discovery – zjistit skutečný stav – bez zdlouhavých otázek.

Postupuj přesně podle struktury:

### KROK 1 – Zeptej se: „Mám provést automatické zjištění tvého prostředí? (ANO/NE)“

Pokud ANO → vygeneruj jediný skript (PowerShell nebo cmd/batch) podle KROKU 2.
Pokud NE → přejdi do režimu ručního zjišťování (KROK 3).

### KROK 2 – Automatický discovery skript (pro ANO)

Vygeneruj skript (PowerShell preferovaný, pokud nevíš, že ho mám, použij cmd).  
Skript musí:

- Být samostatný (jeden blok kódu ke zkopírování a spuštění).
- Nepožadovat instalaci modulů (jen built‑in).
- Vytvořit strukturovaný výstup – JSON (nejlépe) nebo text s oddělovači.
- Zjistit a vypsat:
  - `%USERPROFILE%` a `%HOME%` (pokud existuje)
  - Doménu (`%USERDOMAIN%`) a název počítače (`%COMPUTERNAME%`)
  - Prvních 20 položek `%PATH%`
  - Zda je OneDrive aktivní a zda přesměrovává `Documents`, `Desktop`, `Pictures`
  - Zda existují složky `.config`, `bin`, `dev\projects` v profilu
  - Zda běží proces s oknem obsahujícím "WORK", "HOME" nebo "overlay"
  - Verzi PowerShellu (pokud je dostupný)
  - Seznam nainstalovaných nástrojů: `git`, `node`, `python`, `code` (pomocí `where` nebo `Get-Command`)

Po spuštění skriptu mi uživatel pošle výstup. Ty (AI) si jej přečteš a na jeho základě přejdeš do KROKU 4.

### KROK 3 – Ruční zjišťování (pro NE)

Polož mi maximálně 3 otázky, ale každou doplň o **návrh, jak si to můžu zjistit sám jednoduše a reprodukovatelně**.

Příklad:  
> „Potřebuji znát doménu. Spusť v cmd `echo %USERDOMAIN%` a napiš mi výstup. Pokud chceš, můžu místo toho navrhnout skript.“

Nepokládej otázky jako „Jaké nástroje používáš?“ – místo toho: „Spusť `where git` a napiš, zda to něco vrátí.“

Po obdržení odpovědí přejdi do KROKU 4.

### KROK 4 – Návrh testů, oprav, struktury a landing page

Teprve až máš k dispozici data z KROKU 2 nebo KROKU 3, navrhni:

1. **Testovací skript** (např. `Test-DevEnvironment.ps1`) – zkontroluje, zda je prostředí v pořádku (env:HOME, PATH, OneDrive, overlay, kontext, existence složek, Git repa).
2. **Opravný skript** (např. `Repair-DevEnvironment.ps1`) s přepínačem `-WhatIf`, který:
   - Nastaví `env:HOME` pomocí `setx` (pokud chybí)
   - Vyčistí PATH (ponechá jen systémové + `%HOME%\bin`)
   - Opraví přesměrování složek OneDrive (přes registr nebo symlinky)
   - Vytvoří chybějící adresáře (`.config\powershell`, `bin`, `dev\projects`)
   - Naklonuje nebo aktualizuje repo `system-workflow`
3. **Doporučenou adresářovou strukturu** (textový strom) pro oddělení WORK/HOME. Zahrň umístění:
   - Projektů (osobních i pracovních)
   - Pracovních dokumentů (faktury, smlouvy)
   - Downloadů (dočasné vs. trvalé)
   - Dočasných chatů (AI konverzace, exporty)
   - Dokumentace (návody, architektura)
   - Workflow diagramů (UML, BPMN – jako text nebo obrázky)
   - Skriptů (PowerShell, Python, bat)
   - Landing page (osobní rozcestník)
   - Ke každé položce uveď, zda se synchronizuje (OneDrive / Git / lokálně).
4. **Landing page** (HTML nebo terminálové menu) – rozcestník s odkazy na klíčové složky a akcemi (např. tlačítka „Otevřít projekty“, „Uložit kontext“).
5. **Checklist nasazení** – co mám udělat krok za krokem na firemním PC (doména PPG) a na domácím PC (včetně ošetření firemních omezení).

Všechny skripty a návrhy musí být **reprodukovatelné** – stačí je spustit a fungují bez dalších zásahů.

**Začni Krokem 1 – polož mi jedinou otázku, zda mám provést automatické zjištění.**

---

### Reasonix

<details>
<summary>Reasoning</summary>

The user is asking me to start with Step 1: ask them whether to run automatic discovery or proceed with manual discovery. Let me follow their instructions exactly and ask the single question.

</details>

## KROK 1 – Automatické zjištění prostředí

Mám vygenerovat automatický discovery skript, který spustíš na svém Windows a pošleš mi jeho výstup?

> **Tool · `ask_choice`**

```json
{"question": "Mám provést automatické zjištění tvého prostředí?", "options": [{"id": "auto", "title": "ANO – vygeneruj mi discovery skript", "summary": "Jeden PowerShell skript ke zkopírování a spuštění. Výstup mi pošleš zpět k analýze."}, {"id": "manual", "title": "NE – chci ruční zjišťování", "summary": "Ptej se mě maximálně 3 otázkami, ke každé dostanu návod jak si odpověď zjistit sám."}]}
```

```
user picked: auto
```

<details>
<summary>Reasoning</summary>

The user chose "auto" — they want me to generate an automatic discovery script. Now I need to follow Step 2:

Generate a single PowerShell script (preferred) or cmd/batch script that:

- Is self-contained (one block of code to copy and run)
- Does NOT require installing modules (only built-in)
- Creates structured output – JSON (preferred) or text with delimiters
- Discovers and outputs:
  - `%USERPROFILE%` and `%HOME%` (if exists)
  - Domain (`%USERDOMAIN%`) and computer name (`%COMPUTERNAME%`)
  - First 20 entries of `%PATH%`
  - Whether OneDrive is active and whether it redirects `Documents`, `Desktop`, `Pictures`
  - Whether folders `.config`, `bin`, `dev\projects` exist in profile
  - Whether a process with window containing "WORK", "HOME", or "overlay" is running
  - PowerShell version (if available)
  - List of installed tools: `git`, `node`, `python`, `code` (using `where` or `Get-Command`)

I'll write PowerShell since that's the preferred option. Let me craft a comprehensive script that outputs JSON.

For OneDrive detection, I need to check:
- If OneDrive is running (process)
- Check registry for known folder redirections (Documents, Desktop, Pictures)

For the "process with window containing WORK, HOME, overlay" — this is likely about checking for overlay software or window titles that might indicate work/home context.

Let me write a thorough script.

</details>

## KROK 2 – Automatický discovery skript

Zkopíruj celý tento blok, vlož ho do **PowerShellu spuštěného jako běžný uživatel** (ne jako Admin) a stiskni Enter. Skript nic neinstaluje, nic nemění – pouze čte stav systému a vypíše JSON.

```powershell
# Discovery-DevEnvironment.ps1 — spustit v PowerShellu 5.1+ (nebo PowerShell 7)
# Výstup: JSON na stdout, shrnutí do souboru na ploše

$ErrorActionPreference = "SilentlyContinue"
$out = [ordered]@{}

# === ZÁKLADNÍ PROMĚNNÉ ===
$out.UserProfile     = $env:USERPROFILE
$out.Home            = $env:HOME
$out.HomeDrive       = $env:HOMEDRIVE
$out.HomePath        = $env:HOMEPATH
$out.LocalAppData    = $env:LOCALAPPDATA
$out.AppData         = $env:APPDATA
$out.UserDomain      = $env:USERDOMAIN
$out.ComputerName    = $env:COMPUTERNAME
$out.UserName        = $env:USERNAME
$out.SystemDrive     = $env:SystemDrive
$out.Temp            = $env:TEMP
$out.PSVersion       = $PSVersionTable.PSVersion.ToString()
$out.PSEdition       = $PSVersionTable.PSEdition
$out.OS              = (Get-CimInstance Win32_OperatingSystem).Caption
$out.OSVersion       = [Environment]::OSVersion.Version.ToString()
$out.Is64Bit         = [Environment]::Is64BitOperatingSystem

# === PATH (prvních 20 položek, rozděleno) ===
$pathEntries = $env:PATH -split ';' | Where-Object { $_ -ne '' }
$out.PathCount       = $pathEntries.Count
$out.PathEntries     = @($pathEntries | Select-Object -First 20)

# === ONEDRIVE ===
$oneDriveRegPaths = @(
    "HKCU:\Software\Microsoft\OneDrive\Accounts\Personal",
    "HKCU:\Software\Microsoft\OneDrive\Accounts\Business1",
    "HKCU:\Software\Microsoft\OneDrive\Accounts\Business2"
)
$oneDriveInfo = @()
foreach ($rp in $oneDriveRegPaths) {
    if (Test-Path $rp) {
        $props = Get-ItemProperty -Path $rp -ErrorAction SilentlyContinue
        $oneDriveInfo += [ordered]@{
            Path      = $rp
            UserFolder= $props.UserFolder
            UserEmail = $props.UserEmail
        }
    }
}
$out.OneDriveAccounts = $oneDriveInfo

# OneDrive přesměrování složek (známé složky)
$knownFolderGUIDs = @{
    "Desktop"   = "{B4BFCC3A-DB2C-424C-B029-7FE99A87C641}"
    "Documents" = "{FDD39AD0-238F-46AF-ADB4-6C85480369C7}"
    "Pictures"  = "{33E28130-4E1E-4676-835A-98395C3BC3BB}"
    "Music"     = "{4BD8D571-6D19-48D3-BE97-422220080E43}"
    "Videos"    = "{18989B1D-99B5-455B-841C-AB7C74E4DDFC}"
}
$knownFolders = [ordered]@{}
foreach ($name in $knownFolderGUIDs.Keys) {
    $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders"
    if (Test-Path $regPath) {
        $val = (Get-ItemProperty -Path $regPath -Name $name -ErrorAction SilentlyContinue).$name
        if ($val) {
            $knownFolders[$name] = [ordered]@{
                Path       = $val
                IsOneDrive = $val -match 'OneDrive'
            }
        }
    }
}
$out.KnownFolderRedirects = $knownFolders

# OneDrive proces
$oneDriveProc = Get-Process -Name "OneDrive" -ErrorAction SilentlyContinue
$out.OneDriveRunning     = ($null -ne $oneDriveProc)

# OneDrive složka v profilu
$oneDriveDirs = @(Get-ChildItem -Path "$env:USERPROFILE" -Directory -Filter "OneDrive*" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name)
$out.OneDriveProfileDirs = $oneDriveDirs

# === ADRESÁŘOVÁ STRUKTURA ===
$checkDirs = @(".config", "bin", "dev\projects", "dev", ".local", ".ssh", "Documents", "Desktop", "Downloads")
$dirStatus = [ordered]@{}
foreach ($d in $checkDirs) {
    $full = Join-Path $env:USERPROFILE $d
    $dirStatus[$d] = [ordered]@{
        Exists = Test-Path $full
        Path   = $full
    }
}
$out.Directories = $dirStatus

# === PROCESY S OKNY ===
Add-Type @"
using System;
using System.Runtime.InteropServices;
using System.Text;
public class Win32 {
    [DllImport("user32.dll")]
    public static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll")]
    public static extern int GetWindowText(IntPtr hWnd, StringBuilder text, int count);
    [DllImport("user32.dll")]
    public static extern bool EnumWindows(EnumWindowsProc enumProc, IntPtr lParam);
    public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);
    [DllImport("user32.dll")]
    public static extern bool IsWindowVisible(IntPtr hWnd);
    [DllImport("user32.dll")]
    public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);
}
"@

$windowList = [System.Collections.ArrayList]::new()
$keywords = @("WORK", "HOME", "overlay", "PPG", "VPN", "Remote", "Citrix", "RDP")
$callback = {
    param([IntPtr]$hwnd, [IntPtr]$lparam)
    if ([Win32]::IsWindowVisible($hwnd)) {
        $sb = New-Object System.Text.StringBuilder(256)
        [Win32]::GetWindowText($hwnd, $sb, 256) | Out-Null
        $title = $sb.ToString()
        if ($title.Length -gt 0) {
            $procId = 0
            [Win32]::GetWindowThreadProcessId($hwnd, [ref]$procId) | Out-Null
            try { $procName = (Get-Process -Id $procId -ErrorAction SilentlyContinue).ProcessName } catch { $procName = "?" }
            $hit = $false
            foreach ($kw in $keywords) { if ($title -match $kw) { $hit = $true; break } }
            if ($hit) {
                [void]$windowList.Add(@{ Title=$title; Process=$procName; PID=$procId })
            }
        }
    }
    return $true
}
$delegate = [Win32+EnumWindowsProc]$callback
[Win32]::EnumWindows($delegate, [IntPtr]::Zero) | Out-Null
$out.WindowMatches = @($windowList)

# === NÁSTROJE ===
$tools = [ordered]@{
    git    = $null
    node   = $null
    npm    = $null
    python = $null
    python3= $null
    code   = $null
    winget = $null
    choco  = $null
    scoop  = $null
    pwsh   = $null
    wsl    = $null
    docker = $null
    ssh    = $null
    gh     = $null
    nvm    = $null
    rustup = $null
    cargo  = $null
    dotnet = $null
    java   = $null
    make   = $null
    cmake  = $null
}
$envPathEntries = $env:PATH -split ';' | Where-Object { $_ -ne '' }

foreach ($tool in $tools.Keys) {
    # Zkus Get-Command
    $cmd = Get-Command $tool -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($cmd) {
        $ver = ""
        try {
            switch ($tool) {
                'git'    { $ver = (& git --version 2>&1) -join ' ' }
                'node'   { $ver = (& node --version 2>&1) -join ' ' }
                'npm'    { $ver = (& npm --version 2>&1) -join ' ' }
                'python' { $ver = (& python --version 2>&1) -join ' ' }
                'python3'{ $ver = (& python3 --version 2>&1) -join ' ' }
                'code'   { $ver = (& code --version 2>&1 | Select-Object -First 1) -join ' ' }
                'pwsh'   { $ver = (& pwsh --version 2>&1) -join ' ' }
                'wsl'    { $ver = (& wsl --version 2>&1) -join ' ' }
                'docker' { $ver = (& docker --version 2>&1) -join ' ' }
                'ssh'    { $ver = (& ssh -V 2>&1) -join ' ' }
                'gh'     { $ver = (& gh --version 2>&1 | Select-Object -First 1) -join ' ' }
                'cargo'  { $ver = (& cargo --version 2>&1) -join ' ' }
                'dotnet' { $ver = (& dotnet --version 2>&1) -join ' ' }
                'java'   { $ver = (& java -version 2>&1 | Select-Object -First 1) -join ' ' }
                'make'   { $ver = (& make --version 2>&1 | Select-Object -First 1) -join ' ' }
                'cmake'  { $ver = (& cmake --version 2>&1 | Select-Object -First 1) -join ' ' }
                'winget' { $ver = (& winget --version 2>&1) -join ' ' }
                'choco'  { $ver = (& choco --version 2>&1) -join ' ' }
                'scoop'  { $ver = (& scoop --version 2>&1) -join ' ' }
                'nvm'    { $ver = (& nvm version 2>&1) -join ' ' }
                'rustup' { $ver = (& rustup --version 2>&1) -join ' ' }
                default  { 
                    try { $ver = (& $tool --version 2>&1) -join ' ' } catch {}
                }
            }
        } catch { $ver = "detected but version check failed" }
        $tools[$tool] = [ordered]@{
            Path    = $cmd.Source
            Version = $ver.Trim()
            Type    = $cmd.CommandType.ToString()
        }
    } else {
        $tools[$tool] = $null
    }
}
$out.Tools = $tools

# === REGISTR – klíčové položky ===
# PowerShell profil
$pwshProfiles = [ordered]@{
    CurrentUserCurrentHost  = $PROFILE.CurrentUserCurrentHost
    CurrentUserAllHosts     = $PROFILE.CurrentUserAllHosts
    AllUsersCurrentHost     = $PROFILE.AllUsersCurrentHost
    AllUsersAllHosts        = $PROFILE.AllUsersAllHosts
}
$profileStatus = [ordered]@{}
foreach ($p in $pwshProfiles.GetEnumerator()) {
    $profileStatus[$p.Name] = [ordered]@{
        Path   = $p.Value
        Exists = Test-Path $p.Value
    }
}
$out.PowerShellProfiles = $profileStatus

# === GIT KONFIG (globální) ===
$gitConfig = [ordered]@{}
try {
    $gitConfig.UserName  = (& git config --global user.name 2>&1) -join ' '
    $gitConfig.UserEmail = (& git config --global user.email 2>&1) -join ' '
    $gitConfig.DefaultBranch = (& git config --global init.defaultBranch 2>&1) -join ' '
    $gitconfigPath = "$env:USERPROFILE\.gitconfig"
    $gitConfig.ConfigFileExists = Test-Path $gitconfigPath
} catch {
    $gitConfig.Error = "git not available or config missing"
}
$out.GitConfig = $gitConfig

# === DISKY A VOLNÉ MÍSTO ===
$drives = @(Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Used -gt 0 } | ForEach-Object {
    [ordered]@{
        Name     = $_.Name
        Root     = $_.Root
        UsedGB   = [math]::Round($_.Used / 1GB, 1)
        FreeGB   = [math]::Round($_.Free / 1GB, 1)
        TotalGB  = [math]::Round(($_.Used + $_.Free) / 1GB, 1)
    }
})
$out.Drives = $drives

# === VÝSTUP ===
$json = $out | ConvertTo-Json -Depth 5

# Uložit na plochu
$desktop = [Environment]::GetFolderPath("Desktop")
$outFile = Join-Path $desktop "discovery-result.json"
$json | Set-Content -Path $outFile -Encoding UTF8

# Vypsat na stdout
Write-Output $json

Write-Host ""
Write-Host "========================================"  -ForegroundColor Green
Write-Host " HOTOVO – výstup uložen do:" -ForegroundColor Green
Write-Host "   $outFile" -ForegroundColor Yellow
Write-Host "========================================"  -ForegroundColor Green
Write-Host ""
Write-Host "Pošli mi celý výstup z konzole (JSON) zpět do chatu." -ForegroundColor Cyan
```

### Jak spustit

1. Otevři **PowerShell** (Windows PowerShell 5.1 nebo PowerShell 7 – funguje v obou).
2. Zkopíruj celý blok výše a vlož ho do okna PowerShellu.
3. Stiskni **Enter** – skript proběhne během pár sekund.
4. Zkopíruj **celý výstup z konzole** (včetně zelené hlavičky na konci) a pošli mi ho sem.

Skript zároveň uloží výsledek do souboru `discovery-result.json` na tvé ploše – můžeš ho použít jako zálohu.

---

### You

vylepsi o detekci - 

company? finemni ? HOME, env path , shelly , terminaly, jazyk osverze

---

### Reasonix

<details>
<summary>Reasoning</summary>

The user wants me to improve the discovery script with additional detection for:
- Company/domain detection (is it a corporate machine?)
- "finemni" - I think this means "firemní" (Czech for "company/corporate")
- HOME environment variable details
- Environment PATH details
- Shells installed (PowerShell, cmd, bash, WSL, etc.)
- Terminals available (Windows Terminal, ConEmu, etc.)
- OS language/version

Let me create an enhanced version of the script with these additional checks. The user is Czech, so "finemni" likely means "firemní" = corporate environment detection.

Let me build a comprehensive enhanced script:

1. **Company detection**: Check USERDOMAIN against known corporate domains, check for domain-joined status, check registry for corporate policies, VPN software, SCCM/MDM presence
2. **HOME env**: Already have basic, but add more detail - is it set? what value? does it differ from USERPROFILE?
3. **PATH analysis**: Already have first 20, but add: duplicates detection, non-existent paths, system vs user PATH separation
4. **Shells**: Detect PowerShell versions, WSL distros, Git Bash, MSYS2, Cygwin, cmd availability
5. **Terminals**: Windows Terminal, ConEmu, Cmder, Alacritty, Hyper, Fluent Terminal, default terminal setting
6. **OS language**: system locale, UI language, keyboard layouts

Let me rewrite the script with these enhancements.

</details>

## KROK 2 – Rozšířený discovery skript

Níže je vylepšená verze. Detekuje navíc: **firemní prostředí** (doména, GPO, MDM, VPN klienty, SCCM), **HOME** detailně, **PATH** (duplicity, neexistující cesty, rozdělení System/User), **shelly** (všechny verze PowerShellu, WSL distribuce, Git Bash, MSYS2, Cygwin, cmd), **terminály** (Windows Terminal, ConEmu, Cmder, Alacritty, Hyper, Fluent), **jazyk a verzi OS**.

Zkopíruj celý blok → vlož do PowerShellu → Enter → výstup pošli sem.

```powershell
# Discovery-DevEnvironment-v2.ps1 — rozšířená detekce prostředí
# Spustit v PowerShellu (5.1+ nebo 7.x) jako běžný uživatel (ne Admin).
# Nic nemění, nic neinstaluje – pouze čte.

$ErrorActionPreference = "SilentlyContinue"
$out = [ordered]@{}
$ts  = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$out.GeneratedAt = $ts

# ═══════════════════════════════════════════
#  1. OPERAČNÍ SYSTÉM + JAZYK
# ═══════════════════════════════════════════
$os = Get-CimInstance Win32_OperatingSystem
$out.OS = [ordered]@{
    Caption           = $os.Caption
    Version           = $os.Version
    BuildNumber       = $os.BuildNumber
    OSArchitecture    = $os.OSArchitecture
    InstallDate       = $os.InstallDate
    LastBootUpTime    = $os.LastBootUpTime
    RegisteredUser    = $os.RegisteredUser
    WindowsDirectory  = $os.WindowsDirectory
    SystemDirectory   = $os.SystemDirectory
}
$out.Is64Bit = [Environment]::Is64BitOperatingSystem

# Jazyk / locale
$out.Language = [ordered]@{
    CurrentCulture       = (Get-Culture).Name
    CurrentCultureDisplay= (Get-Culture).DisplayName
    CurrentUICulture     = (Get-UICulture).Name
    CurrentUICultureDisplay=(Get-UICulture).DisplayName
    SystemLocale         = (Get-WinSystemLocale -ErrorAction SilentlyContinue).Name
    InputLanguages       = @(Get-WinUserLanguageList -ErrorAction SilentlyContinue | ForEach-Object { $_.LanguageTag })
}
# Installed language packs
$langPacks = @(Get-WinUserLanguageList -ErrorAction SilentlyContinue | ForEach-Object { $_.LanguageTag })
$out.LanguagePacks   = $langPacks
# Keyboard layouts
$keyboards = @(Get-WinUserLanguageList -ErrorAction SilentlyContinue | ForEach-Object { 
    [ordered]@{ LanguageTag=$_.LanguageTag; InputMethodTips=@($_.InputMethodTips) }
})
$out.Keyboards = $keyboards

# ═══════════════════════════════════════════
#  2. DOMÉNA / FIREMNÍ DETEKCE
# ═══════════════════════════════════════════
$out.UserDomain   = $env:USERDOMAIN
$out.ComputerName = $env:COMPUTERNAME
$out.UserName     = $env:USERNAME

# Je počítač v doméně?
try {
    $domain = Get-CimInstance Win32_ComputerSystem
    $out.Domain = [ordered]@{
        Domain              = $domain.Domain
        DomainRole          = $domain.DomainRole  # 0=Standalone,2=Workgroup,3=Member,4=BDC,5=PDC
        PartOfDomain        = $domain.PartOfDomain
        Workgroup           = $domain.Workgroup
        Manufacturer        = $domain.Manufacturer
        Model               = $domain.Model
        SystemType          = $domain.SystemType
        TotalPhysicalMemoryGB = [math]::Round($domain.TotalPhysicalMemory / 1GB, 1)
    }
} catch {}

# Firemní indikátory – check známých domén
$corporateDomains = @("PPG", "CONTOSO", "MS", "MSFT", "FABRIKAM", "ACME", "CORP")
$out.CorporateHints = [ordered]@{
    UserDomainMatchesKnown = $corporateDomains -contains $env:USERDOMAIN
    ComputerNamePrefix     = $env:COMPUTERNAME -match "^(DT|LT|NB|WS|VM|SRV|CLT)-"  # typické firemní prefixy
}

# GPO – existuje klíč registru pro GPO?
$gpoKeys = @(
    "HKLM:\Software\Microsoft\Windows\CurrentVersion\Group Policy",
    "HKLM:\Software\Policies\Microsoft",
    "HKCU:\Software\Policies\Microsoft",
    "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies"
)
$gpoInfo = [ordered]@{}
foreach ($k in $gpoKeys) {
    $gpoInfo[$k] = Test-Path $k
}
$out.GPO_RegistryKeys = $gpoInfo

# SCCM / Intune / MDM
$sccmClient = Test-Path "HKLM:\Software\Microsoft\SMS\Mobile Client"
$intuneEnrolled = Test-Path "HKLM:\Software\Microsoft\Enrollments"
$out.MDM = [ordered]@{
    SCCM_Client_Present = $sccmClient
    Intune_Enrollments  = $intuneEnrolled
}

# VPN klienti
$vpnIndicators = [ordered]@{
    Cisco_AnyConnect    = Test-Path "C:\Program Files*\Cisco\Cisco AnyConnect*"
    GlobalProtect       = Test-Path "C:\Program Files*\Palo Alto Networks\GlobalProtect*"
    FortiClient         = Test-Path "C:\Program Files*\Fortinet\FortiClient*"
    PulseSecure         = Test-Path "C:\Program Files*\Pulse Secure*"
    OpenVPN             = Test-Path "C:\Program Files*\OpenVPN*"
    WireGuard           = Test-Path "C:\Program Files*\WireGuard*"
    CheckPoint          = Test-Path "C:\Program Files*\CheckPoint*"
    Zscaler             = Test-Path "C:\Program Files*\Zscaler*"
    Netskope            = Test-Path "C:\Program Files*\Netskope*"
}
$out.VPN_Clients = $vpnIndicators

# Antivirus / EDR
$avProducts = @(Get-CimInstance -Namespace "root\SecurityCenter2" -ClassName AntivirusProduct -ErrorAction SilentlyContinue | 
    ForEach-Object { [ordered]@{ Name=$_.displayName; State=$_.productState } })
$out.Antivirus = $avProducts

# Proxy
$out.Proxy = [ordered]@{
    SystemProxy = (Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings" -ErrorAction SilentlyContinue).ProxyServer
    ProxyEnable = (Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings" -ErrorAction SilentlyContinue).ProxyEnable
    env_http_proxy  = $env:http_proxy
    env_https_proxy = $env:https_proxy
    env_no_proxy    = $env:no_proxy
}

# ═══════════════════════════════════════════
#  3. UŽIVATELSKÝ PROFIL + HOME
# ═══════════════════════════════════════════
$out.Profile = [ordered]@{
    USERPROFILE = $env:USERPROFILE
    HOMEDRIVE   = $env:HOMEDRIVE
    HOMEPATH    = $env:HOMEPATH
    HOME        = $env:HOME
    HOME_set    = ($null -ne $env:HOME -and $env:HOME -ne '')
    HOME_differs_from_USERPROFILE = ($env:HOME -ne $env:USERPROFILE)
    LOCALAPPDATA = $env:LOCALAPPDATA
    APPDATA     = $env:APPDATA
    SystemDrive = $env:SystemDrive
    TEMP        = $env:TEMP
    TMP         = $env:TMP
    OneDrive_root = $env:OneDrive
    OneDriveCommercial = $env:OneDriveCommercial
}

# ═══════════════════════════════════════════
#  4. PATH – DŮKLADNÁ ANALÝZA
# ═══════════════════════════════════════════
$rawPath = $env:PATH
$pathAll   = $rawPath -split ';' | Where-Object { $_ -ne '' }
$pathDistinct = $pathAll | Select-Object -Unique

# Duplicity
$dupes = $pathAll | Group-Object | Where-Object { $_.Count -gt 1 } | ForEach-Object { $_.Name }

# Neexistující cesty
$missingPaths = @()
foreach ($p in $pathDistinct) {
    $expanded = $p
    try { $expanded = [Environment]::ExpandEnvironmentVariables($p) } catch {}
    if (!(Test-Path $expanded)) {
        $missingPaths += $p
    }
}

# Rozdělení: System PATH vs User PATH
$systemPathRaw = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" -ErrorAction SilentlyContinue).PATH
$userPathRaw   = (Get-ItemProperty -Path "HKCU:\Environment" -ErrorAction SilentlyContinue).PATH
$systemPaths = if ($systemPathRaw) { $systemPathRaw -split ';' | Where-Object { $_ -ne '' } } else { @() }
$userPaths   = if ($userPathRaw)   { $userPathRaw -split ';' | Where-Object { $_ -ne '' }   } else { @() }

# PATH typické nástrojové složky
$toolPaths = @{}
$toolPatterns = @{
    Python   = 'Python'
    Node     = 'nodejs'
    Git      = 'Git\cmd|Git\bin|git\cmd|git\bin'
    Ruby     = 'Ruby'
    Java     = 'Java|jdk|jre|adopt|zulu|temurin'
    Go       = 'Go\bin'
    Rust     = '.cargo\bin|rustup'
    DotNet   = 'dotnet'
    PHP      = 'php'
    Perl     = 'Perl|Strawberry'
    MSYS2    = 'msys2|msys64'
    Cygwin   = 'cygwin|cygwin64'
    MinGW    = 'mingw'
    WindowsApps  = 'WindowsApps'
    Scoop    = 'scoop'
    Chocolatey = 'chocolatey'
    Anaconda = 'Anaconda|Miniconda|conda'
    NVM      = 'nvm|nvm-windows'
    Docker   = 'Docker'
    Oracle   = 'Oracle'
    Intel    = 'Intel'
    NVIDIA   = 'NVIDIA'
    SysInternals = 'Sysinternals'
}
foreach ($pat in $toolPatterns.Keys) {
    $matches = @($pathDistinct | Where-Object { $_ -match $toolPatterns[$pat] })
    if ($matches.Count -gt 0) { $toolPaths[$pat] = $matches }
}

$out.PATH = [ordered]@{
    TotalEntries        = $pathAll.Count
    UniqueEntries       = $pathDistinct.Count
    DuplicateCount      = $pathAll.Count - $pathDistinct.Count
    Duplicates          = @($dupes)
    MissingPaths        = @($missingPaths)
    First10             = @($pathDistinct | Select-Object -First 10)
    SystemPathCount     = $systemPaths.Count
    UserPathCount       = $userPaths.Count
    DetectedToolPaths   = $toolPaths
}

# ═══════════════════════════════════════════
#  5. SHELLY
# ═══════════════════════════════════════════
$shells = [ordered]@{}

# PowerShell verze
$shells.PowerShell = [ordered]@{
    Version     = $PSVersionTable.PSVersion.ToString()
    Edition     = $PSVersionTable.PSEdition
    InstallPath = (Get-Command powershell.exe -ErrorAction SilentlyContinue).Source
}

# PowerShell 7 (pwsh) – samostatně
$pwshCmd = Get-Command pwsh.exe -ErrorAction SilentlyContinue
if ($pwshCmd) {
    $pwshVersions = @()
    $pwshPaths = @($pwshCmd.Source)
    # Další možné cesty
    "C:\Program Files\PowerShell\7\pwsh.exe",
    "$env:LOCALAPPDATA\Microsoft\WindowsApps\pwsh.exe",
    "$env:ProgramFiles\PowerShell\7-preview\pwsh.exe" | ForEach-Object {
        if (Test-Path $_ -and $_ -notin $pwshPaths) { $pwshPaths += $_ }
    }
    foreach ($pp in $pwshPaths) {
        try { $pv = (& $pp -NoProfile -Command '$PSVersionTable.PSVersion.ToString()' 2>&1) } catch { $pv = "unknown" }
        $pwshVersions += "$pp → $pv"
    }
    $shells.PowerShell7 = [ordered]@{
        Found    = $true
        Paths    = $pwshVersions
    }
} else {
    $shells.PowerShell7 = [ordered]@{ Found = $false }
}

# cmd.exe
$shells.CMD = [ordered]@{
    Path = (Get-Command cmd.exe -ErrorAction SilentlyContinue).Source
}

# WSL
$wslExe = Get-Command wsl.exe -ErrorAction SilentlyContinue
if ($wslExe) {
    $wslDistros = @()
    try {
        $wslList = & wsl.exe --list --quiet 2>&1
        foreach ($d in $wslList) {
            if ($d.Trim() -ne '') {
                $ver = ""
                try { $ver = (& wsl.exe -d $d.Trim() -- cat /etc/os-release 2>&1 | Select-String "^PRETTY_NAME=").ToString() } catch {}
                $wslDistros += "$($d.Trim()) | $ver"
            }
        }
    } catch {}
    $shells.WSL = [ordered]@{
        Path     = $wslExe.Source
        Version  = try { (& wsl --version 2>&1 | Select-Object -First 1) -join ' ' } catch { "unknown" }
        Distros  = $wslDistros
        DefaultDistro = try { (& wsl --status 2>&1 | Select-String "Default Distribution") -join ' ' } catch { "" }
    }
} else {
    $shells.WSL = $null
}

# Git Bash
$gitBashPaths = @(
    "C:\Program Files\Git\bin\bash.exe",
    "C:\Program Files (x86)\Git\bin\bash.exe",
    "$env:LOCALAPPDATA\Programs\Git\bin\bash.exe"
) | Where-Object { Test-Path $_ }
$shells.GitBash = [ordered]@{
    Found = $gitBashPaths.Count -gt 0
    Paths = $gitBashPaths
}

# MSYS2
$msys2Paths = @(
    "C:\msys64\usr\bin\bash.exe",
    "C:\msys2\usr\bin\bash.exe",
    "$env:USERPROFILE\msys64\usr\bin\bash.exe"
) | Where-Object { Test-Path $_ }
$shells.MSYS2 = [ordered]@{
    Found = $msys2Paths.Count -gt 0
    Paths = $msys2Paths
}

# Cygwin
$cygwinPaths = @("C:\cygwin64\bin\bash.exe", "C:\cygwin\bin\bash.exe") | Where-Object { Test-Path $_ }
$shells.Cygwin = [ordered]@{
    Found = $cygwinPaths.Count -gt 0
    Paths = $cygwinPaths
}

# BusyBox / embedded
$bb = Get-Command busybox.exe -ErrorAction SilentlyContinue
$shells.BusyBox = if ($bb) { $bb.Source } else { $null }

$out.Shells = $shells

# ═══════════════════════════════════════════
#  6. TERMINÁLY
# ═══════════════════════════════════════════
$terminals = [ordered]@{}

# Windows Terminal
$wtPaths = @(
    "$env:LOCALAPPDATA\Microsoft\WindowsApps\wt.exe",
    "$env:LOCALAPPDATA\Microsoft\WindowsApps\WindowsTerminal.exe",
    "C:\Program Files\WindowsApps\Microsoft.WindowsTerminal*\wt.exe",
    "C:\Program Files\WindowsApps\Microsoft.WindowsTerminal*\WindowsTerminal.exe"
)
$wtFound = @($wtPaths | Where-Object { Test-Path $_ })
$terminals.WindowsTerminal = [ordered]@{
    Found      = $wtFound.Count -gt 0
    Paths      = $wtFound
    Settings   = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_*\LocalState\settings.json"
    SettingsExists = (Test-Path "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_*\LocalState\settings.json")
}

# ConEmu
$conemuPaths = @(
    "C:\Program Files\ConEmu\ConEmu64.exe",
    "C:\Program Files\ConEmu\ConEmu.exe",
    "C:\Tools\ConEmu\ConEmu64.exe",
    "$env:USERPROFILE\Tools\ConEmu\ConEmu64.exe"
) | Where-Object { Test-Path $_ }
$terminals.ConEmu = [ordered]@{ Found = $conemuPaths.Count -gt 0; Paths = $conemuPaths }

# Cmder
$cmderPaths = @("C:\Tools\Cmder\Cmder.exe", "$env:USERPROFILE\Cmder\Cmder.exe", "C:\Cmder\Cmder.exe") | Where-Object { Test-Path $_ }
$terminals.Cmder = [ordered]@{ Found = $cmderPaths.Count -gt 0; Paths = $cmderPaths }

# Alacritty
$alacritty = Get-Command alacritty.exe -ErrorAction SilentlyContinue
$terminals.Alacritty = [ordered]@{
    Found = ($null -ne $alacritty)
    Path  = if ($alacritty) { $alacritty.Source } else { $null }
}

# Hyper
$hyperPaths = @("$env:LOCALAPPDATA\hyper\Hyper.exe", "$env:ProgramFiles\Hyper\Hyper.exe") | Where-Object { Test-Path $_ }
$terminals.Hyper = [ordered]@{ Found = $hyperPaths.Count -gt 0; Paths = $hyperPaths }

# Fluent Terminal
$fluentPaths = @("$env:LOCALAPPDATA\Microsoft\WindowsApps\flute.exe") | Where-Object { Test-Path $_ }
$terminals.FluentTerminal = [ordered]@{ Found = $fluentPaths.Count -gt 0 }

# Tabby (Terminus)
$tabby = Get-Command tabby.exe -ErrorAction SilentlyContinue
$terminals.Tabby = [ordered]@{ Found = ($null -ne $tabby); Path = if($tabby){$tabby.Source}else{$null} }

# WezTerm
$wezterm = Get-Command wezterm.exe -ErrorAction SilentlyContinue
$terminals.WezTerm = [ordered]@{ Found = ($null -ne $wezterm); Path = if($wezterm){$wezterm.Source}else{$null} }

# Windows Console Host (conhost – default)
$terminals.DefaultConsoleHost = [ordered]@{
    Path = (Get-Command conhost.exe -ErrorAction SilentlyContinue).Source
}

# Nastavení výchozího terminálu (Win11)
$defaultTerminalReg = try { 
    (Get-ItemProperty -Path "HKCU:\Console\%%Startup" -ErrorAction SilentlyContinue).DelegationConsole
} catch { $null }
$terminals.DefaultTerminal_Reg = $defaultTerminalReg

$out.Terminals = $terminals

# ═══════════════════════════════════════════
#  7. ONEDRIVE
# ═══════════════════════════════════════════
$oneDriveRegPaths = @(
    "Personal"  = "HKCU:\Software\Microsoft\OneDrive\Accounts\Personal",
    "Business1" = "HKCU:\Software\Microsoft\OneDrive\Accounts\Business1",
    "Business2" = "HKCU:\Software\Microsoft\OneDrive\Accounts\Business2"
)
$odInfo = [ordered]@{}
foreach ($key in $oneDriveRegPaths.Keys) {
    $rp = $oneDriveRegPaths[$key]
    if (Test-Path $rp) {
        $props = Get-ItemProperty -Path $rp -ErrorAction SilentlyContinue
        $odInfo[$key] = [ordered]@{
            UserFolder = $props.UserFolder
            UserEmail  = $props.UserEmail
            DisplayName= $props.DisplayName
        }
    }
}
$out.OneDrive_Accounts = $odInfo

# Přesměrování známých složek
$knownFolders = [ordered]@{
    Desktop   = "{B4BFCC3A-DB2C-424C-B029-7FE99A87C641}"
    Documents = "{FDD39AD0-238F-46AF-ADB4-6C85480369C7}"
    Pictures  = "{33E28130-4E1E-4676-835A-98395C3BC3BB}"
    Music     = "{4BD8D571-6D19-48D3-BE97-422220080E43}"
    Videos    = "{18989B1D-99B5-455B-841C-AB7C74E4DDFC}"
    Downloads = "{374DE290-123F-4565-9164-39C4925E467B}"
}
$redirects = [ordered]@{}
$regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders"
if (Test-Path $regPath) {
    foreach ($name in $knownFolders.Keys) {
        $val = (Get-ItemProperty -Path $regPath -Name $name -ErrorAction SilentlyContinue).$name
        if ($val) {
            $redirects[$name] = [ordered]@{
                Path       = $val
                IsOneDrive = $val -match 'OneDrive'
                Exists     = (Test-Path ([Environment]::ExpandEnvironmentVariables($val)))
            }
        }
    }
}
$out.KnownFolderRedirects = $redirects

# OneDrive proces
$odProc = Get-Process -Name "OneDrive" -ErrorAction SilentlyContinue
$out.OneDrive_Running = ($null -ne $odProc)
$out.OneDrive_ProfileDirs = @(Get-ChildItem "$env:USERPROFILE" -Directory -Filter "OneDrive*" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name)

# ═══════════════════════════════════════════
#  8. ADRESÁŘOVÁ STRUKTURA
# ═══════════════════════════════════════════
$checkDirs = @(
    ".config", ".config\powershell", "bin", "dev", "dev\projects",
    ".local", ".ssh", ".gnupg", ".docker",
    "Documents", "Desktop", "Downloads", "Pictures", "Music", "Videos",
    "source", "repos", "workspace", "projects",
    "AppData\Local\nvim", "AppData\Local\nvim-data",
    ".vscode", ".gitconfig", ".npmrc", ".wgetrc", ".curlrc"
)
$dirStatus = [ordered]@{}
foreach ($d in $checkDirs) {
    $full = Join-Path $env:USERPROFILE $d
    $dirStatus[$d] = [ordered]@{
        Exists = Test-Path $full
        Path   = $full
    }
}
$out.Directories = $dirStatus

# ═══════════════════════════════════════════
#  9. NÁSTROJE – VERZE DETEKCE
# ═══════════════════════════════════════════
function Get-ToolInfo($name, $versionArgs) {
    $cmd = Get-Command $name -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $cmd) { return $null }
    $ver = ""
    $verFull = ""
    try {
        if ($versionArgs) {
            $verFull = (& $name @versionArgs 2>&1 | Select-Object -First 5) -join " | "
            $ver = (& $name @versionArgs 2>&1 | Select-Object -First 1) -join ' '
        } else {
            $verFull = (& $name --version 2>&1 | Select-Object -First 5) -join " | "
            $ver = (& $name --version 2>&1 | Select-Object -First 1) -join ' '
        }
    } catch { $ver = "version check failed" }
    return [ordered]@{
        Path    = $cmd.Source
        Version = $ver.Trim()
        Type    = $cmd.CommandType.ToString()
    }
}

$tools = [ordered]@{
    git       = ,@('--version')
    node      = ,@('--version')
    npm       = ,@('--version')
    npx       = ,@('--version')
    yarn      = ,@('--version')
    pnpm      = ,@('--version')
    python    = ,@('--version')
    python3   = ,@('--version')
    py        = ,@('--version')
    pip       = ,@('--version')
    pip3      = ,@('--version')
    code      = ,@('--version')
    code-insiders = ,@('--version')
    cursor    = ,@('--version')
    vim       = ,@('--version')
    nvim      = ,@('--version')
    emacs     = ,@('--version')
    winget    = ,@('--version')
    choco     = ,@('--version')
    scoop     = ,@('--version')
    docker    = ,@('--version')
    podman    = ,@('--version')
    ssh       = ,@('-V')
    gh        = ,@('--version')
    glab      = ,@('--version')
    nvm       = ,@('version')
    rustup    = ,@('--version')
    cargo     = ,@('--version')
    rustc     = ,@('--version')
    dotnet    = ,@('--version')
    java      = ,@('-version')
    javac     = ,@('-version')
    mvn       = ,@('--version')
    gradle    = ,@('--version')
    make      = ,@('--version')
    cmake     = ,@('--version')
    gcc       = ,@('--version')
    g++       = ,@('--version')
    clang     = ,@('--version')
    cl        = ,@('--version')
    msbuild   = ,@('--version')
    perl      = ,@('--version')
    ruby      = ,@('--version')
    go        = ,@('version')
    php       = ,@('--version')
    sqlite3   = ,@('--version')
    curl      = ,@('--version')
    wget      = ,@('--version')
    tar       = ,@('--version')
    7z        = ,@('--help')
    ffmpeg    = ,@('-version')
    pandoc    = ,@('--version')
    jq        = ,@('--version')
    yq        = ,@('--version')
    fzf       = ,@('--version')
    rg        = ,@('--version')
    fd        = ,@('--version')
    bat       = ,@('--version')
    eza       = ,@('--version')
    delta     = ,@('--version')
    lazygit   = ,@('--version')
    zoxide    = ,@('--version')
    starship  = ,@('--version')
    oh-my-posh = ,@('--version')
}
$toolResults = [ordered]@{}
foreach ($tool in $tools.Keys) {
    $toolResults[$tool] = Get-ToolInfo $tool $tools[$tool]
}
$out.Tools = $toolResults

# ═══════════════════════════════════════════
# 10. GIT KONFIG
# ═══════════════════════════════════════════
$gitConfig = [ordered]@{}
try {
    $gitConfig = [ordered]@{
        'user.name'           = (& git config --global user.name 2>&1) -join ' '
        'user.email'          = (& git config --global user.email 2>&1) -join ' '
        'init.defaultBranch'  = (& git config --global init.defaultBranch 2>&1) -join ' '
        'core.editor'         = (& git config --global core.editor 2>&1) -join ' '
        'core.autocrlf'       = (& git config --global core.autocrlf 2>&1) -join ' '
        'http.proxy'          = (& git config --global http.proxy 2>&1) -join ' '
        'https.proxy'         = (& git config --global https.proxy 2>&1) -join ' '
        'credential.helper'   = (& git config --global credential.helper 2>&1) -join ' '
        '.gitconfig_exists'   = Test-Path "$env:USERPROFILE\.gitconfig"
    }
} catch {
    $gitConfig.Error = "git not available"
}
$out.GitConfig = $gitConfig

# SSH klíče
$sshDir = "$env:USERPROFILE\.ssh"
$sshInfo = [ordered]@{
    DirExists = Test-Path $sshDir
    Keys      = @(if (Test-Path $sshDir) { Get-ChildItem $sshDir -Filter "*.pub" -ErrorAction SilentlyContinue | ForEach-Object { $_.Name } })
    Config    = Test-Path "$sshDir\config"
    KnownHosts= Test-Path "$sshDir\known_hosts"
}
$out.SSH = $sshInfo

# ═══════════════════════════════════════════
# 11. OKNA – FIREMNÍ / OVERLAY
# ═══════════════════════════════════════════
Add-Type @"
using System;
using System.Runtime.InteropServices;
using System.Text;
public class W32 {
    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumWinProc lpEnumFunc, IntPtr lParam);
    [DllImport("user32.dll")] public static extern int GetWindowText(IntPtr hWnd, StringBuilder lpString, int nMaxCount);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);
    public delegate bool EnumWinProc(IntPtr hWnd, IntPtr lParam);
}
"@

$windowList = [System.Collections.ArrayList]::new()
$keywords = @("WORK", "HOME", "overlay", "PPG", "VPN", "Remote", "Citrix", "RDP", "VMware", "VirtualBox", "Hyper-V", "Sandbox", "Admin", "Domain", "GPO", "MDM", "Intune", "SCCM", "Zscaler")
$callback = {
    param([IntPtr]$hwnd, [IntPtr]$lparam)
    if ([W32]::IsWindowVisible($hwnd)) {
        $sb = New-Object System.Text.StringBuilder(512)
        [W32]::GetWindowText($hwnd, $sb, 512) | Out-Null
        $title = $sb.ToString()
        if ($title.Length -gt 0) {
            $procId = 0
            [W32]::GetWindowThreadProcessId($hwnd, [ref]$procId) | Out-Null
            try { $procName = (Get-Process -Id $procId -ErrorAction SilentlyContinue).ProcessName } catch { $procName = "?" }
            $hit = $false
            foreach ($kw in $keywords) { if ($title -match $kw) { $hit = $true; break } }
            if ($hit) {
                [void]$windowList.Add(@{ Title=$title; Process=$procName })
            }
        }
    }
    return $true
}
$delegate = [W32+EnumWinProc]$callback
[W32]::EnumWindows($delegate, [IntPtr]::Zero) | Out-Null
$out.WindowMatches = @($windowList)

# ═══════════════════════════════════════════
# 12. DISKY
# ═══════════════════════════════════════════
$drives = @(Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Used -gt 0 -or $_.Name -eq $env:SystemDrive[0] } | ForEach-Object {
    [ordered]@{
        Name    = $_.Name
        Root    = $_.Root
        UsedGB  = [math]::Round($_.Used / 1GB, 1)
        FreeGB  = [math]::Round($_.Free / 1GB, 1)
        TotalGB = [math]::Round(($_.Used + $_.Free) / 1GB, 1)
    }
})
$out.Drives = $drives

# ═══════════════════════════════════════════
# VÝSTUP
# ═══════════════════════════════════════════
$json = $out | ConvertTo-Json -Depth 6

# Uložit na plochu
$desktop = [Environment]::GetFolderPath("Desktop")
$outFile = Join-Path $desktop "discovery-result-v2.json"
$json | Set-Content -Path $outFile -Encoding UTF8

# Stdout
Write-Output $json

Write-Host ""
Write-Host "══════════════════════════════════════════" -ForegroundColor Green
Write-Host " HOTOVO – JSON uložen do:" -ForegroundColor Green
Write-Host "   $outFile" -ForegroundColor Yellow
Write-Host "══════════════════════════════════════════" -ForegroundColor Green
Write-Host ""
Write-Host "Pošli mi CELÝ výstup z konzole (JSON) zpět do chatu." -ForegroundColor Cyan
Write-Host "Pro jistotu můžeš připojit i soubor $outFile." -ForegroundColor Cyan
```

### Co skript nově detekuje (oproti v1)

| Sekce | Co zjišťuje |
|---|---|
| **OS + jazyk** | Verze, build, architektura, systémová locale, UI jazyk, klávesnice |
| **Firemní detekce** | Doménová role, GPO klíče v registru, SCCM/Intune, VPN klienti (Cisco, GlobalProtect, FortiClient, Pulse Secure, OpenVPN, WireGuard, CheckPoint, Zscaler, Netskope), proxy nastavení, antivirus/EDR |
| **HOME** | Zda je nastaveno, zda se liší od `USERPROFILE`, `OneDrive` a `OneDriveCommercial` env |
| **PATH** | Celkový počet, unikátní, duplicity, neexistující cesty, rozdělení System vs User, automatická detekce toolchainů (Python, Node, Git, Java, Go, Rust, MSYS2, Cygwin, Anaconda, NVM…) |
| **Shelly** | PowerShell 5.1 + PowerShell 7.x (všechny nalezené instance), cmd.exe, WSL (všechny distribuce + verze), Git Bash, MSYS2, Cygwin, BusyBox |
| **Terminály** | Windows Terminal (včetně cesty k settings.json), ConEmu, Cmder, Alacritty, Hyper, Fluent, Tabby, WezTerm, výchozí terminál v registru |
| **OneDrive** | Osobní i firemní účty, přesměrování všech známých složek (včetně Downloads), zda složky fyzicky existují |
| **Nástroje** | Rozšířeno na 50+ nástrojů – přibyly: `yarn`, `pnpm`, `cursor`, `vim`, `nvim`, `emacs`, `podman`, `glab`, `rustc`, `javac`, `mvn`, `gradle`, `gcc`, `g++`, `clang`, `cl`, `msbuild`, `perl`, `ruby`, `go`, `php`, `curl`, `wget`, `tar`, `7z`, `ffmpeg`, `pandoc`, `jq`, `yq`, `fzf`, `rg`, `fd`, `bat`, `eza`, `delta`, `lazygit`, `zoxide`, `starship`, `oh-my-posh` |
| **Git** | Proxy nastavení, credential helper, core.editor, core.autocrlf |
| **SSH** | Existence `.ssh`, seznam veřejných klíčů, config, known_hosts |

Čekám na tvůj JSON výstup – jakmile ho pošleš, přejdu do **KROKU 4** (testovací skript, opravný skript, adresářová struktura, landing page, checklist nasazení).

---

### You

co verzovani co gisty co proffil ?  
co multiplatform, portability, link generate readme versioning ? 
plan for prompt, automation,  research improvements, cross agentic, platform, 
independency run 
easy re-use
ai cross check , brainstorm posibility  for always review and

---

### Reasonix

<details>
<summary>Reasoning</summary>

The user is asking me to expand the discovery script even further. Let me parse their requests:

1. **Verzování (versioning)** – detect version managers, version files (.nvmrc, .python-version, .tool-versions, etc.)
2. **Gisty (Gists)** – GitHub Gists? Or maybe "gists" as in key insights/summaries?
3. **Profil** – profile files (.bashrc, .profile, .zshrc, PowerShell profiles, starship.toml, etc.)
4. **Multiplatform / portability** – WSL, Docker, cross-platform indicators
5. **Link generation** – symlinks, junctions, hardlinks in the environment
6. **README versioning** – check for README files, documentation
7. **Plan for prompt** – prompt templates, AI prompt files
8. **Automation** – scheduled tasks, cron-like, startup scripts
9. **Research improvements** – research notes, knowledge base
10. **Cross-agentic** – tools for AI agents (MCP servers, agent configs, API keys)
11. **Platform independency** – portable apps, standalone installations
12. **Easy re-use** – templates, dotfiles, reproducible setups
13. **AI cross-check** – AI configurations, multiple AI tools
14. **Brainstorm possibilities** – maybe a meta-section about what could be improved

The user wants me to enhance the discovery script with ALL of these dimensions. Let me think about what's feasible to detect via PowerShell without installing modules.

Actually, let me re-read the user's message more carefully. They're asking a lot of questions in a shorthand/bullet-point style. I think they want me to:

1. Add versioning detection (version managers like nvm, rustup, pyenv, asdf, mise)
2. Add "gists" - maybe GitHub Gists CLI detection, or maybe they mean "gist" as in key files
3. Profile files detection (.bashrc, .zshrc, PowerShell profiles, starship configs, etc.)
4. Multiplatform/portability indicators (WSL, Docker containers, portable apps)
5. Symlinks and junctions in the environment
6. README files and documentation versioning
7. Prompt templates / automation scripts
8. Cross-agent AI tools (MCP servers, API keys for various AIs)
9. Platform independence (portable installs, scoop, standalone tools)
10. Reusable scripts/templates
11. AI cross-check capabilities
12. A "brainstorm" section at the end of the discovery

I should enhance the script further and explain what was added. Rather than generating yet another massive script in full, maybe I should show the key NEW sections they're asking about and integrate them.

Actually, the user seems to want me to just DO it - enhance the script with all these additional dimensions. Let me create a v3 with these additions. I'll focus on the most impactful additions and be strategic about what can actually be detected.

Let me create the enhanced v3 with these new sections.

</details>

## KROK 2 – Discovery v3: kompletní inventura prostředí

Rozumím – chceš detekci **všeho**, co souvisí s reprodukovatelným, multiplatformním a agent-ready prostředím. Níže je **v3** s 11 novými sekcemi:

| Nová sekce | Co detekuje |
|---|---|
| **Verzování** | `nvm`, `fnm`, `volta`, `pyenv`, `asdf`, `mise`, `rustup`, `sdkman`, `.nvmrc`, `.python-version`, `.node-version`, `.tool-versions`, `.terraform-version`, `.ruby-version` |
| **Gisty** | `gh gist`, `gist` CLI, GitHub CLI auth stav, tokeny, keychain |
| **Profily** | Všechny shell RC soubory, PowerShell `$PROFILE`, Starship, Oh-My-Posh, prompt frameworky |
| **Multiplatform** | WSL detail, Docker Desktop + kontejnery, PortableApps, AppImage/WSLg, architekturní emulace |
| **Symlinky/Junky** | `.config` symlinky, `bin` symlinky, junction points, OneDrive junctiony |
| **README + Docs** | `README.md`, `ARCHITECTURE.md`, `CONTRIBUTING.md`, `CHANGELOG.md`, verzované v repozitářích |
| **Prompt + Automatizace** | Prompt templates, system instructions, `Taskfile`, `Makefile`, `justfile`, Scheduled Tasks |
| **Cross‑Agentic** | MCP servery (Claude, Continue, Open Interpreter), API klíče (env + konfigy), agent config soubory |
| **Portabilita** | Scoop, Chocolatey, Winget manifest, portable instalace (bez instalátoru), AppExecutionAlias |
| **AI Cross‑check** | Více AI klientů vedle sebe, konflikty, duplicitní konfigurace |
| **Brainstorm** | Meta‑analýza – co v prostředí hoří, co je čisté, doporučení na míru |

Zkopíruj → vlož → Enter → pošli výstup.

```powershell
# Discovery-DevEnvironment-v3.ps1 — KOMPLETNÍ inventura prostředí
# Spustit v PowerShellu jako běžný uživatel. Nic nemění.

$ErrorActionPreference = "SilentlyContinue"
$ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss zzz"
$out = [ordered]@{ GeneratedAt = $ts }

# ═══════════════════════════════════════════
# 1. OS + JAZYK
# ═══════════════════════════════════════════
$os = Get-CimInstance Win32_OperatingSystem
$out.OS = [ordered]@{
    Caption=$os.Caption; Version=$os.Version; Build=$os.BuildNumber
    Arch=$os.OSArchitecture; Installed=$os.InstallDate; Booted=$os.LastBootUpTime
    RegisteredUser=$os.RegisteredUser; WindowsDir=$os.WindowsDirectory
}
$out.Is64Bit = [Environment]::Is64BitOperatingSystem
$out.Language = [ordered]@{
    Culture=(Get-Culture).Name; CultureDisplay=(Get-Culture).DisplayName
    UICulture=(Get-UICulture).Name; UICultureDisplay=(Get-UICulture).DisplayName
    SystemLocale=(Get-WinSystemLocale -EA SilentlyContinue).Name
    Inputs=@(Get-WinUserLanguageList -EA SilentlyContinue | % { "$($_.LanguageTag):$($_.InputMethodTips -join ',')" })
}

# ═══════════════════════════════════════════
# 2. DOMÉNA / FIREMNÍ
# ═══════════════════════════════════════════
$cs = Get-CimInstance Win32_ComputerSystem
$out.Domain = [ordered]@{
    Domain=$cs.Domain; Role=$cs.DomainRole; PartOfDomain=$cs.PartOfDomain
    Manufacturer=$cs.Manufacturer; Model=$cs.Model; RAM_GB=[math]::Round($cs.TotalPhysicalMemory/1GB,1)
}
$out.User = [ordered]@{ Domain=$env:USERDOMAIN; Computer=$env:COMPUTERNAME; Name=$env:USERNAME }
$out.CorpFlags = [ordered]@{
    KnownCorpDomain=@("PPG","CONTOSO","MS","MSFT") -contains $env:USERDOMAIN
    GPO_HKLM=(Test-Path "HKLM:\Software\Policies\Microsoft")
    GPO_HKCU=(Test-Path "HKCU:\Software\Policies\Microsoft")
    SCCM=(Test-Path "HKLM:\Software\Microsoft\SMS\Mobile Client")
    Intune=(Test-Path "HKLM:\Software\Microsoft\Enrollments")
}
$out.VPN = [ordered]@{
    CiscoAnyConnect=(Test-Path "C:\Program Files*\Cisco\Cisco AnyConnect*")
    GlobalProtect=(Test-Path "C:\Program Files*\Palo Alto Networks\GlobalProtect*")
    FortiClient=(Test-Path "C:\Program Files*\Fortinet\FortiClient*")
    Zscaler=(Test-Path "C:\Program Files*\Zscaler*")
    OpenVPN=(Test-Path "C:\Program Files*\OpenVPN*")
    WireGuard=(Test-Path "C:\Program Files*\WireGuard*")
}
$out.Proxy = [ordered]@{
    System=(Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings" -EA SilentlyContinue).ProxyServer
    Enabled=(Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings" -EA SilentlyContinue).ProxyEnable
    http_proxy=$env:http_proxy; https_proxy=$env:https_proxy; no_proxy=$env:no_proxy
}
$out.Antivirus = @(Get-CimInstance -Namespace root\SecurityCenter2 -Class AntivirusProduct -EA SilentlyContinue | % { $_.displayName })

# ═══════════════════════════════════════════
# 3. PROFIL + HOME
# ═══════════════════════════════════════════
$out.Profile = [ordered]@{
    USERPROFILE=$env:USERPROFILE; HOMEDRIVE=$env:HOMEDRIVE; HOMEPATH=$env:HOMEPATH
    HOME=$env:HOME; HOME_set=($null -ne $env:HOME -and $env:HOME -ne '')
    HOME_differs=($env:HOME -ne $env:USERPROFILE)
    LOCALAPPDATA=$env:LOCALAPPDATA; APPDATA=$env:APPDATA
    OneDrive=$env:OneDrive; OneDriveCommercial=$env:OneDriveCommercial
}

# ═══════════════════════════════════════════
# 4. PATH – HLOUBKOVÁ ANALÝZA
# ═══════════════════════════════════════════
$raw = $env:PATH; $all = $raw -split ';' | ? { $_ -ne '' }
$uniq = $all | Select-Object -Unique
$dupes = $all | Group-Object | ? { $_.Count -gt 1 } | % { $_.Name }
$missing = @(); foreach ($p in $uniq) { try { $ep = [Environment]::ExpandEnvironmentVariables($p) } catch { $ep=$p }; if (!(Test-Path $ep)) { $missing += $p } }
$sysPath = ((Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" -EA SilentlyContinue).PATH -split ';' | ? {$_})
$usrPath = ((Get-ItemProperty "HKCU:\Environment" -EA SilentlyContinue).PATH -split ';' | ? {$_})
$out.PATH = [ordered]@{
    Total=$all.Count; Unique=$uniq.Count; DupCount=($all.Count-$uniq.Count)
    Duplicates=@($dupes); Missing=@($missing); First10=@($uniq|select -First 10)
    SystemPathCount=$sysPath.Count; UserPathCount=$usrPath.Count
}

# ═══════════════════════════════════════════
# 5. SHELLY (všechny)
# ═══════════════════════════════════════════
$sh = [ordered]@{
    PowerShell5=[ordered]@{ Version=$PSVersionTable.PSVersion.ToString(); Edition=$PSVersionTable.PSEdition; Path=(Get-Command powershell.exe -EA SilentlyContinue).Source }
    CMD=(Get-Command cmd.exe -EA SilentlyContinue).Source
}
$pwshPaths = @((Get-Command pwsh.exe -EA SilentlyContinue).Source | ? {$_})
"$env:ProgramFiles\PowerShell\7\pwsh.exe","$env:LOCALAPPDATA\Microsoft\WindowsApps\pwsh.exe" | % { if ((Test-Path $_) -and $_ -notin $pwshPaths) { $pwshPaths+=$_ } }
$pwshInfo = @(); foreach ($pp in $pwshPaths) { try { $v = & $pp -NoProfile -c '$PSVersionTable.PSVersion.ToString()' 2>&1 } catch { $v="?" }; $pwshInfo+="$pp → $v" }
$sh.PowerShell7=[ordered]@{ Found=($pwshInfo.Count -gt 0); Instances=$pwshInfo }
# WSL
$wsl = Get-Command wsl.exe -EA SilentlyContinue
if ($wsl) {
    $distros=@(); try { & wsl --list --quiet 2>&1 | % { $t=$_.Trim(); if ($t) { $os=""; try { $os=(& wsl -d $t -- cat /etc/os-release 2>&1|sls "^PRETTY_NAME=").ToString() } catch {}; $distros+="$t | $os" } } } catch {}
    $sh.WSL=[ordered]@{ Path=$wsl.Source; Version=(& wsl --version 2>&1|select -First 1); Distros=$distros }
} else { $sh.WSL=$null }
# Git Bash / MSYS2 / Cygwin
$sh.GitBash=@("C:\Program Files\Git\bin\bash.exe","$env:LOCALAPPDATA\Programs\Git\bin\bash.exe") | ? { Test-Path $_ }
$sh.MSYS2=@("C:\msys64\usr\bin\bash.exe","C:\msys2\usr\bin\bash.exe") | ? { Test-Path $_ }
$sh.Cygwin=@("C:\cygwin64\bin\bash.exe","C:\cygwin\bin\bash.exe") | ? { Test-Path $_ }
$out.Shells = $sh

# ═══════════════════════════════════════════
# 6. TERMINÁLY
# ═══════════════════════════════════════════
$term = [ordered]@{
    WindowsTerminal=[ordered]@{
        Found=((Test-Path "$env:LOCALAPPDATA\Microsoft\WindowsApps\wt.exe") -or (Test-Path "$env:LOCALAPPDATA\Microsoft\WindowsApps\WindowsTerminal.exe"))
        SettingsExists=(Test-Path "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_*\LocalState\settings.json")
    }
    ConEmu=@("C:\Program Files\ConEmu\ConEmu64.exe","$env:USERPROFILE\Tools\ConEmu\ConEmu64.exe")|?{Test-Path $_}
    Cmder=@("C:\Tools\Cmder\Cmder.exe","$env:USERPROFILE\Cmder\Cmder.exe")|?{Test-Path $_}
    Alacritty=if($a=Get-Command alacritty.exe -EA SilentlyContinue){$a.Source}else{$null}
    Hyper=@("$env:LOCALAPPDATA\hyper\Hyper.exe")|?{Test-Path $_}
    Tabby=if($t=Get-Command tabby.exe -EA SilentlyContinue){$t.Source}else{$null}
    WezTerm=if($w=Get-Command wezterm.exe -EA

---

### You

co verzovani co gisty co proffil ?  
co multiplatform, portability, link generate readme versioning ? 
plan for prompt, automation,  research improvements, cross agentic, platform, 
independency run 
easy re-use
ai cross check , brainstorm posibility  for always review and

---

### Reasonix

<details>
<summary>Reasoning</summary>

The user is asking a lot of questions in Czech that seem to be about expanding the discovery/planning further. Let me break down what they're asking:

1. **Co verzování, co gisty, co profil?** - What about versioning, gists, profiles? They want versioning of the environment/config, gist integration, and profile management.

2. **Co multiplatform, portability, link generate readme versioning?** - Multiplatform support, portability, link generation, README versioning.

3. **Plan for prompt, automation, research improvements, cross agentic, platform, independency run, easy re-use** - They want a comprehensive plan covering prompts, automation, research, cross-agent compatibility, platform independence, easy reuse.

4. **AI cross check, brainstorm possibility for always review** - AI cross-checking, brainstorming possibilities for continuous review.

This seems like they want me to expand the discovery script AND the overall plan to cover these aspects. But I'm still waiting for them to actually run the discovery script and send me the JSON output. Let me address their questions while also reminding them that I need the discovery output to proceed to KROK 4.

Actually, wait - they haven't sent me the JSON output yet. They're asking me to expand the plan with these additional concerns. Let me address what they're asking about and also integrate these into the discovery and planning.

Let me re-read: "co verzovani co gisty co proffil ? co multiplatform, portability, link generate readme versioning ? plan for prompt, automation, research improvements, cross agentic, platform, independency run easy re-use ai cross check , brainstorm posibility for always review and"

These are all questions/requests about what the overall solution should include. They want me to expand the scope to cover:

- Versioning of dev environment configs
- Gist integration (GitHub Gists for sharing snippets)
- Profile management (PowerShell profiles, terminal profiles)
- Multiplatform considerations (Windows/Mac/Linux)
- Portability (dotfiles, portable configs)
- Link generation and README versioning
- Prompt automation
- Cross-agent compatibility (different AI agents)
- Platform independence
- Easy reuse
- AI cross-check and continuous review

I should respond by acknowledging these concerns and expanding the discovery script AND the plan to cover them. But I also need to remind them to run the script.

Actually, the user seems to want me to expand the discovery script further before they run it. Let me add these dimensions to the script. They want:

1. **Versioning detection** - what version control systems, dotfiles repos, config management
2. **Gists** - GitHub Gists CLI, pastebin tools
3. **Profiles** - PowerShell profiles, terminal profiles, shell rc files
4. **Multiplatform/portability** - WSL, Docker, cross-platform tools
5. **Link generation** - symlinks, junctions, hardlinks
6. **README/documentation** - existing README files, documentation structure
7. **Prompt management** - where prompts are stored
8. **Cross-agent compatibility** - what AI tools/agents are installed
9. **Platform independence** - containerization, package managers
10. **Easy reuse** - package manager lockfiles, reproducible setups

Let me expand the discovery script to cover these and then provide the expanded plan.

But I should also remind them: I still need the discovery output to proceed. Let me expand the script now.

</details>

Rozumím – chceš, abych do discovery a celého plánu zapracoval i tyhle dimenze **ještě předtím, než skript spustíš**. Pojďme to rozšířit.

## Rozšířený discovery – v3 (verzování, gisty, profily, multiplatform, portabilita, AI nástroje)

Toto je **finální verze** skriptu. Přidává:

| Nová sekce | Co detekuje |
|---|---|
| **Verzování** | Git repa v `dev/`, `projects/`, `source/`, `repos/`; SVN, Mercurial; GitHub/GitLab CLI autentizaci |
| **Gisty** | `gh gist`, `gist` gem, `pastebinit`, `nc` – kam můžeš sdílet snippety |
| **Profily** | PowerShell `$PROFILE` (všechny 4 varianty + obsah), Terminal settings.json, `.bashrc`/`.zshrc`/`.profile` ve WSL, `.gitconfig`, starship/oh-my-posh konfigy, VS Code `settings.json` |
| **Multiplatform** | WSL distribuce s detaily, Docker/Podman, Nix, paketové manažery (winget/choco/scoop/npm global/pip global/cargo global), Node version manažery (nvm, fnm, volta) |
| **Portabilita** | Symbolické linky a junction pointy, `dotfiles` repa, `XDG_*` proměnné, portable aplikace |
| **AI / Agenti** | VS Code rozšíření (Copilot, Cody, Continue), `claude-cli`, `codex`, `aider`, `tgpt`, `ollama`, LM Studio, GPT4All, `llm` (Simon Willison), Open Interpreter |
| **Prompty** | Adresáře `/prompts`, `/templates`, `.reasonix/`, `.cursorrules`, `.github/copilot-instructions.md` |
| **Dokumentace** | README soubory, `mkdocs`, `mdbook`, `docusaurus`, `obsidian` vaulty |

### Skript – zkopíruj a spusť v PowerShellu

```powershell
# Discovery-DevEnvironment-v3.ps1 — FINÁLNÍ rozšířená detekce
# Verzování · Gisty · Profily · Multiplatform · Portabilita · AI nástroje · Prompty
# Sp

---

### You

reiterate uplne znovu -
s tim ze hledame idealni krok 0

---

### Reasonix

<details>
<summary>Reasoning</summary>

The user is asking me to rethink the entire approach from "Step 0" — they want me to consider:

1. **Versioning** — of scripts, configs, prompts
2. **Gists** — as a distribution/versioning mechanism
3. **Profiles** — different profiles for WORK vs HOME vs other contexts
4. **Multi-platform / portability** — not just Windows, but cross-platform thinking
5. **Link generation / README versioning** — how to version and share
6. **Plan for prompt automation** — how to make prompts reusable
7. **Research improvements** — continuous improvement loop
8. **Cross-agentic** — working across different AI agents/platforms
9. **Platform independency** — the setup should work regardless of platform
10. **Easy re-use** — everything should be easily reusable
11. **AI cross-check / brainstorm** — always review, always improve

They want me to go back to "Step 0" — the ideal foundation before even the discovery script. Let me think about this carefully.

What they're really asking for is a **meta-framework** — a system that:
- Is versioned (git + gists for distribution)
- Has profiles (WORK/HOME/etc.)
- Is portable across platforms (Windows, Linux, macOS)
- Has self-documenting prompts that evolve
- Can be used by any AI agent (not just me)
- Has a built-in review/improvement loop
- Is easy to bootstrap from zero

Let me think about the ideal Step 0 architecture, then present it as a plan.

Key insight: The discovery script itself should be part of a versioned repo. The "prompts" should be markdown files that any AI can read. The whole system should be a git repo with a clear structure.

Let me design this:

```
dev-environment/
├── README.md                    # Landing + quickstart
├── CHANGELOG.md                 # Version history
├── prompts/                     # AI prompts (versioned, reusable)
│   ├── discover.md              # Discovery prompt (Step 2)
│   ├── repair.md                # Repair prompt template
│   ├── review.md                # Cross-check / review prompt
│   └── bootstrap.md             # Full bootstrap prompt
├── scripts/                     # Platform-specific scripts
│   ├── windows/
│   │   ├── discover.ps1         # Windows discovery
│   │   ├── repair.ps1           # Windows repair
│   │   └── test.ps1             # Windows test
│   ├── linux/
│   │   ├── discover.sh
│   │   ├── repair.sh
│   │   └── test.sh
│   └── macos/
│       ├── discover.sh
│       ├── repair.sh
│       └── test.sh
├── profiles/                    # Context profiles
│   ├── WORK.ppg.md              # PPG work profile
│   ├── HOME.md                  # Home profile
│   └── default.md               # Default fallback
├── configs/                     # Dotfiles templates
│   ├── .gitconfig.template
│   ├── .npmrc.template
│   ├── starship.toml
│   └── terminal-settings.json
├── docs/                        # Documentation
│   ├── architecture.md          # System design
│   ├── directory-structure.md   # Recommended layout
│   ├── landing-page.md          # Personal dashboard design
│   └── deployment-checklist.md  # Step-by-step deployment
└── .github/                     # CI / automation (optional)
    └── workflows/
        └── validate.yml
```

The "gist" approach: Each prompt file can be shared as a gist. The README has version badges. The whole thing is a git repo — `git clone` = bootstrap.

Now, the user asked me to "reiterate completely from scratch" and find the "ideal Step 0." Let me present this as a structured plan.

I should NOT just do it — I should present the plan/architecture first, get alignment, then execute. Let me use `submit_plan` for this since it's a significant architectural decision.

Actually wait, let me re-read the user's message more carefully. They want:

1. Versioning — what to version, how
2. Gists — as distribution
3. Profiles — WORK/HOME separation
4. Multi-platform — Windows + Linux + macOS
5. Link generation / README versioning
6. Plan for prompt automation
7. Research improvements
8. Cross-agentic (works with any AI)
9. Platform independence
10. Easy re-use
11. AI cross-check / brainstorm / always review

And they say "reiterate completely from scratch — find the ideal Step 0."

So they want me to present a complete meta-architecture. This is big enough for `submit_plan`. Let me write a comprehensive plan.

Actually, I think the user would prefer I just lay out the vision directly in a structured way rather than going through the plan approval gate. They seem to want to see the design, not approve a plan to design it. Let me present it as a proposal/design document, then ask if they want me to actually scaffold it all out.

But the instructions say: "For multi-file refactors, architecture changes, anything expensive to undo, use submit_plan." This IS an architecture proposal. Let me use submit_plan.

Hmm, but the user is in brainstorming/design mode. They want to see the vision. Let me present the design first, then offer to scaffold.

Actually, I think the best approach here is to present the full Step 0 design as a structured response, then ask the one question from Step 1 again within this new framework. The user seems to want to see the whole picture first.

Let me present:

1. The meta-repository structure
2. How versioning works (git + gists)
3. How profiles work
4. How prompts are reusable and versioned
5. How cross-platform works
6. How the AI review loop works
7. Then ask: do you want me to scaffold this, or run discovery first?

This is a design presentation, not an edit operation. Let me just present it.

</details>

## KROK 0 – Meta-framework návrh

Chápu tě. Než se pustíme do discovery, potřebujeme **systém, který to celé drží** — verzovaný, přenositelný, nezávislý na konkrétním AI, multiplatformní. Tady je kompletní návrh od nuly.

---

### 1. Repozitář `dev-environment` — centrální zdroj pravdy

```
dev-environment/
│
├── README.md                        # ⬅️ LANDING PAGE: co to je, jak spustit, odkazy
├── CHANGELOG.md                     # Verzování: co se měnilo (semver)
├── VERSION                          # Aktuální verze (např. 0.2.0)
│
├── prompts/                         # ⬅️ VERZOVANÉ AI PROMPTY (jádro systému)
│   ├── discover.md                  #    Prompt pro discovery (KROK 2)
│   ├── repair.md                    #    Prompt pro opravu (KROK 4)
│   ├── review.md                    #    Prompt pro AI cross-check
│   ├── brainstorm.md                #    Prompt pro vylepšování
│   └── bootstrap.md                 #    Kompletní bootstrap od nuly
│
├── scripts/                         # ⬅️ SPUSTITELNÉ SKRIPTY
│   ├── windows/
│   │   ├── discover.ps1             #    Discovery → JSON
│   │   ├── repair.ps1               #    Oprava s -WhatIf
│   │   └── test.ps1                 #    Test integrity
│   ├── linux/
│   │   ├── discover.sh
│   │   ├── repair.sh
│   │   └── test.sh
│   └── macos/
│       ├── discover.sh
│       ├── repair.sh
│       └── test.sh
│
├── profiles/                        # ⬅️ KONTEXTOVÉ PROFILY
│   ├── default.yaml                 #    Společná konfigurace (jméno, email...)
│   ├── WORK.ppg.yaml                #    Firemní PPG profil (doména, proxy, omezení)
│   ├── HOME.yaml                    #    Domácí profil
│   └── template.yaml                #    Šablona pro nový profil
│
├── dotfiles/                        # ⬅️ ŠABLONY KONFIGURÁKŮ
│   ├── .gitconfig.template
│   ├── .npmrc.template
│   ├── ssh-config.template
│   ├── starship.toml
│   ├── terminal-settings.json       #    Windows Terminal settings
│   └── powershell-profile.ps1
│
├── docs/                            # ⬅️ DOKUMENTACE (ne prompt)
│   ├── directory-structure.md       #    Doporučený strom složek
│   ├── deployment-work.md           #    Checklist firemní PC (PPG)
│   ├── deployment-home.md           #    Checklist domácí PC
│   ├── landing-page.md              #    Návrh rozcestníku
│   └── architecture.md              #    Proč je to takhle navržené
│
├── .githooks/                       #    Hooky pro automatickou validaci
│   └── pre-commit                   #    Validace JSON/YAML před commitem
│
└── .github/                         #    CI (volitelné)
    └── workflows/
        └── validate.yml             #    Spustí test skript na push
```

---

### 2. Verzování — co a jak

| Co verzujeme | Jak | Proč |
|---|---|---|
| **Prompty** (`prompts/*.md`) | Git + sémantické verze | Každá změna promptu může změnit chování AI → musí být dohledatelná |
| **Skripty** (`scripts/`) | Git | Spustitelný kód = standardní vývoj |
| **Profily** (`profiles/*.yaml`) | Git | Konfigurace se mění s prostředím |
| **Dotfiles** (`dotfiles/`) | Git + symlinky z `$HOME` | Centrální zdroj, lokální nasazení |
| **Gisty** | Automaticky z tagů | `v0.2.0` → gist s `discover.md` + `repair.md` pro rychlé sdílení |

**Gist strategie:** Každý release tag automaticky vygeneruje gist(y) s klíčovými soubory. Uživatel jen pošle URL gistu AI → AI si ho stáhne a pracuje. Žádné kopírování bloků kódu.

---

### 3. Profily — WORK vs HOME

Soubor `profiles/HOME.yaml`:

```yaml
id: HOME
domain: ""                    # Žádná doména
oneDrive: personal
proxy: none
restrictions: none            # Plná kontrola
directories:
  projects: ~/dev/projects
  workdocs: ~/Documents/Work
  downloads: ~/Downloads
tools:
  package_manager: scoop      # nebo winget
  terminal: WindowsTerminal
  shell: pwsh
env:
  HOME: "C:\\Users\\jmeno"
```

Soubor `profiles/WORK.ppg.yaml`:

```yaml
id: WORK.ppg
domain: PPG
oneDrive: commercial           # OneDrive for Business
proxy: auto-detect             # Nebo explicitní PAC URL
restrictions:
  no_admin: true               # Nemám admin práva
  no_choco: true               # Chocolatey blokovaný
  no_scoop: true
  vpn_required: true           # GlobalProtect / Cisco
  ports_blocked: [22, 8080]    # Omezené porty
directories:
  projects: ~/dev/projects     # Může být přesměrované OneDrivem
  workdocs: ~/OneDrive - PPG/Documents
env:
  HOME: ""                     # Pravděpodobně chybí → repair skript doplní
```

**Přepínání profilu:** `repair.ps1 -Profile WORK.ppg` aplikuje správná omezení a nastavení.

---

### 4. Multiplatformní přenositelnost

| Vrstva | Windows | Linux | macOS |
|---|---|---|---|
| **Discovery** | `discover.ps1` | `discover.sh` | `discover.sh` |
| **Výstupní formát** | JSON (stejná struktura všude) | JSON | JSON |
| **Správce balíčků** | winget / scoop | apt / dnf / pacman | brew |
| **HOME** | `C:\Users\jméno` | `/home/jméno` | `/Users/jméno` |
| **PATH oddělovač** | `;` | `:` | `:` |
| **OneDrive** | Nativní klient | `rclone` / onedrive-d | `rclone` |

Všechny discovery skripty produkují **identickou JSON strukturu** — AI dostane stejně strukturovaný výstup bez ohledu na platformu.

---

### 5. Prompty jako first-class artefakty

Každý prompt v `prompts/` je **samostatný markdown soubor**, který můžeš:

- **Poslat jako gist** → AI si ho stáhne a provede
- **Nahrát do libovolného AI** (Reasonix, ChatGPT

---

### You

/clean

---

### Reasonix

<details>
<summary>Reasoning</summary>

The user is asking me to rethink the entire approach from scratch. They want me to iterate on "Krok 0" — the ideal starting point — and consider:

1. **Versioning** — how to version the setup (dotfiles, scripts, configs)
2. **Gists** — using GitHub Gists for snippets/configs
3. **Profiles** — different profiles (work vs home, different machines)
4. **Multi-platform** — the setup should work across platforms (Windows, maybe Linux/Mac)
5. **Portability** — the environment should be portable
6. **Link generation** — generating links/references
7. **README versioning** — versioned documentation
8. **Plan for prompt** — how prompts evolve
9. **Automation** — full automation pipeline
10. **Research improvements** — continuous improvement
11. **Cross-agentic** — working across different AI agents
12. **Platform independency** — run anywhere
13. **Easy re-use** — reusable components
14. **AI cross-check** — AI review loops
15. **Brainstorm possibilities** — always review and improve

They're saying: start over completely ("reiterate uplne znovu"), focus on "Krok 0" — the ideal first step that sets up versioning, is cross-platform, portable, agentic, and future-proof.

This is a design/architecture conversation. They want me to:
1. Think about the ideal "Step 0" for a portable, version-controlled, cross-platform dev environment
2. Incorporate all the concepts they mentioned
3. Produce a cohesive plan

Let me think about what "Krok 0" means in this context:

The user wants a **portable developer environment** that:
- Is version-controlled (dotfiles in git, gists for snippets)
- Has profiles (WORK vs HOME)
- Is cross-platform
- Is AI-agent-friendly (can be understood and operated by AI agents)
- Has automated discovery and repair
- Has links/references/README
- Is easily reusable

The ideal "Krok 0" would be a **bootstrap bootstrap** — a minimal seed that:
1. Discovers the environment (like we were doing)
2. Sets up version control for the environment itself
3. Creates profiles
4. Is portable (works on Windows, Linux, Mac)
5. Generates documentation
6. Is AI-reviewable

Let me design this properly and present it as a structured answer. No tools needed — this is a design discussion.

</details>

## KROK 0 — Přehodnocení od nuly

Chápu. Nechceš jednorázový discovery skript. Chceš **systém** — něco, co přežije reinstalaci, přeneseš mezi stroji, verzeš jako kód, a co pochopí jakýkoliv AI agent (včetně tohoto).

Pojďme to vymyslet pořádně.

---

## Co je "Krok 0"

**Jediný soubor**, který když stáhneš a spustíš na holém Windows/Mac/Linux, tak:

```
curl -sL https://raw.githubusercontent.com/<tvuj>/dotfiles/main/bootstrap.ps1 | pwsh -
```

…a za 5 minut máš:

- ✅ Verzované prostředí (Git repo s celým setupem)
- ✅ Automatickou detekci stroje (work/home/VM)
- ✅ Profily (`work.ppg`, `home.personal`, `home.lab`)
- ✅ Multiplatformní kostru (Windows / Linux / macOS)
- ✅ Vygenerované README s odkazy
- ✅ AI-čitelnou strukturu (každý soubor má hlavičku, účel, vazby)

---

## Architektura — 7 souborů, žádná magie

```
~/dev/dotfiles/                   ← Git repo (GitHub public/private)
├── bootstrap.ps1                 ← JEDINÝ vstupní bod (PowerShell, funguje i na Linux/macOS přes pwsh)
├── profile.ps1                   ← Auto-detekce: work? home? lab? VM?
├── profiles/
│   ├── base.json                 ← Výchozí nastavení (společné pro všechny)
│   ├── home.personal.json        ← Domácí PC — volné
│   ├── home.lab.json             ← Domácí lab — experimenty
│   └── work.ppg.json             ← Firemní PPG — omezení, proxy, VPN
├── repair.ps1                    ← Opravný skript (-WhatIf, idempotentní)
├── test.ps1                      ← Testovací skript (fail/pass na každou položku)
├── README.md                     ← Generovaný rozcestník (odkazy na vše)
├── configs/                      ← Verzované konfigy
│   ├── git/.gitconfig
│   ├── pwsh/profile.ps1
│   ├── terminal/settings.json    ← Windows Terminal
│   ├── starship.toml
│   └── vscode/settings.json
├── gists/                        ← Importované gisty (snippety, rychlé skripty)
│   └── .gitkeep
├── docs/                         ← AI-generovaná dokumentace
│   ├── architecture.md
│   ├── workflows.md
│   └── troubleshooting.md
└── .github/
    └── workflows/
        └── validate.yml          ← CI — automaticky testuje bootstrap na Windows+Linux+macOS
```

---

## Klíčové principy

### 1. Verzování = Git + Gists + GitHub Releases

| Co | Jak verzovat |
|---|---|
| **Setup skripty** | Git (`dotfiles` repo) |
| **Konfigy** | Git (symlinky nebo copy z `configs/`) |
| **Rychlé snippety** | GitHub Gists (odkaz z README) |
| **Binárky / stažené nástroje** | GitHub Releases (winget/scoop/brew tahá konkrétní verzi) |
| **Profily** | JSON v `profiles/`, verzované, s `$schema` |
| **README** | Generované z `profiles/*.json` + `docs/` → vždy aktuální |

### 2. Profily = detekce, ne přepínání

`profile.ps1` se rozhodne **automaticky**:

```powershell
# profile.ps1 — auto-detekce profilu
param([string]$Force)

function Get-AutoProfile {
    $domain = $env:USERDOMAIN
    $hostname = $env:COMPUTERNAME
    $manufacturer = (Get-CimInstance Win32_ComputerSystem).Manufacturer

    # Firemní
    if ($domain -in @("PPG", "MS", "CONTOSO")) {
        $corp = ($domain -eq "PPG") ? "work.ppg" : "work.default"
        return $corp
    }
    # Domácí lab (VMware/VirtualBox indikátory)
    if ($manufacturer -match "VMware|VirtualBox|QEMU") {
        return "home.lab"
    }
    # Vše ostatní = domácí
    return "home.personal"
}
```

### 3. Multiplatformní = PowerShell 7 jako lingua franca

- **Windows**: `pwsh.exe` (PowerShell 7)
- **Linux**: `pwsh` (instalovatelný přes `apt`/`dnf`/`pacman`)
- **macOS**: `pwsh` (brew)

Jeden jazyk pro bootstrap → `bootstrap.ps1` funguje všude. Uvnitř se větví podle `$IsWindows` / `$IsLinux` / `$IsMacOS`.

### 4. AI-cross-check = struktura, kterou pochopí každý agent

Každý soubor má hlavičku:

```powershell
# === FILE: repair.ps1 ===========================================
# ROLE:    Idempotentní opravný skript
# INPUT:   profiles/home.personal.json
# OUTPUT:  Nastavené prostředí dle profilu
# RUN:     ./repair.ps1 -WhatIf     # suchý běh
#          ./repair.ps1 -Force      # aplikovat
# REQUIRES: pwsh 7.2+, git, winget
# LINKED:  bootstrap.ps1, test.ps1, profile.ps1
# =================================================================
```

Tohle umí každý AI agent přečíst za 5 sekund a ví, co s tím.

### 5. README = generované, ne psané

```powershell
# bootstrap.ps1 volá na konci:
& ./generate-readme.ps1
```

Výstup: `README.md` s odkazy na:
- Všechny profily (s vysvětlením, proč byl vybrán ten aktuální)
- Klíčové složky (`dev/projects/`, `bin/`, `.config/`)
- Nástroje (verze, cesty)
- Gisty (seznam + odkazy)
- Workflow diagramy (Mermaid v `docs/workflows.md`)

---

## Krok 0 — co teď uděláme

Nenavrhuju jednorázový skript. Navrhuju **repozitář**:

> **Tool · `ask_choice`**

```json
{"question": "Jak chceš pokračovat? Můžu hned začít generovat soubory do repozitáře.", "options": [{"id":"full","title":"Vygeneruj celý dotfiles repozitář","summary":"Všech 7+ souborů: bootstrap.ps1, profile.ps1, profily JSON, repair, test, README, CI workflow. Připraveno ke commitu."},{"id":"bootstrap","title":"Jen bootstrap.ps1 + profile.ps1","summary":"Nejdřív minimální životaschopný seed — spustitelné na Windows, detekce profilu. Zbytek potom."},{"id":"design","title":"Nejdřív projdi návrh struktury detailně","summary":"Projdeme každý soubor, jeho účel, vazby a AI-čitelnost. Pak generujeme."}]}
```

```
user picked: design
```

<details>
<summary>Reasoning</summary>

The user wants to go through the design in detail first before generating any files. Let me walk through the entire architecture, file by file, explaining purpose, inputs/outputs, and how they connect. I should also address all the specific concepts they mentioned: versioning, gists, profiles, multiplatform, portability, link generation, README versioning, prompt planning, automation, research improvements, cross-agentic, platform independency, easy re-use, AI cross-check, brainstorming.

Let me provide a comprehensive design document.

</details>

## Detailní návrh — soubor po souboru

Projdu kompletní architekturu: co který soubor dělá, jak do sebe zapadají, a jak celý systém naplňuje každý z tvých požadavků. Tohle je "specifikace před implementací".

---

# 1. `bootstrap.ps1` — jediný vstupní bod

**Účel:** Spustím na holém stroji. Za 5 minut mám vše.

**Co dělá:**
1. Ověří, že běží PowerShell 7+ (když ne → nabídne instalaci přes winget/brew)
2. Naklonuje `dotfiles` repo (nebo aktualizuje, pokud už existuje)
3. Spustí `profile.ps1` → zjistí, na jakém stroji jsme
4. Načte odpovídající `profiles/<jmeno>.json`
5. Spustí `repair.ps1 -Force` s profilem
6. Spustí `test.ps1` → ověří, že vše sedí
7. Spustí `generate-readme.ps1` → vygeneruje aktuální README
8. Vypíše shrnutí: "Profil `home.personal` na `DESKTOP-ABC`. 42/42 testů OK."

**Idempotence:** Spustit 10× = stejný výsledek. Bezpečné pro existující prostředí.

**Platformy:** `$IsWindows` / `$IsLinux` / `$IsMacOS` → větví se jen uvnitř funkcí.

---

# 2. `profile.ps1` — auto-detekce

**Účel:** Rozhodnout, jaký profil použít. Bez otázek.

**Detekční matice:**

| Podmínka | Profil |
|---|---|
| `$env:USERDOMAIN` = PPG | `work.ppg` |
| `$env:USERDOMAIN` je jiná firemní | `work.default` |
| `Win32_ComputerSystem.Manufacturer` obsahuje VMware/VirtualBox/QEMU/Hyper-V | `home.lab` |
| `hostname` obsahuje `-VM` nebo `-LAB` | `home.lab` |
| `hostname` obsahuje `-SRV` | `home.server` |
| Jinak | `home.personal` |

**Overridy:** `-Force home.lab` → ruční přepnutí. Uloží se do `$HOME/.config/dotfiles/active-profile` pro příští běh.

**Výstup:** Název profilu + cesta k JSON. Nic víc.

---

# 3. `profiles/*.json` — deklarativní definice prostředí

**Účel:** Jeden soubor = kompletní popis prostředí pro daný stroj.

Každý profil dědí z `base.json`. Příklad:

```jsonc
// profiles/home.personal.json
{
  "$schema": "../schemas/profile-v1.json",
  "name": "home.personal",
  "extends": "base",
  "description": "Domácí PC — plná kontrola, žádná omezení",

  "paths": {
    "home": "$env:USERPROFILE",
    "projects": "$home/dev/projects",
    "workDocs": null,
    "downloads": "$home/Downloads",
    "tempChats": "$home/dev/chats",
    "docs": "$home/dev/docs",
    "diagrams": "$home/dev/docs/diagrams",
    "scripts": "$home/dev/scripts",
    "bin": "$home/bin"
  },

  "sync": {
    "configs":    { "method": "git",  "path": "~/dev/dotfiles" },
    "projects":   { "method": "git",  "path": "~/dev/projects" },
    "documents":  { "method": "none", "path": "~/Documents" },
    "downloads":  { "method": "none", "path": "

---

### You

/spatne zaciname s navrhem od 0

---

### Reasonix

<details>
<summary>Reasoning</summary>

The user is saying we're starting the design wrong — they want to go back to absolute zero and rethink from scratch. They don't want me to present a solution. They want me to think about what the IDEAL step 0 is, considering all the concerns they listed.

Let me re-read their original message:

> co verzovani co gisty co proffil ?
> co multiplatform, portability, link generate readme versioning ?
> plan for prompt, automation, research improvements, cross agentic, platform,
> independency run
> easy re-use
> ai cross check , brainstorm posibility for always review and
> reiterate uplne znovu -
> s tim ze hledame idealni krok 0

They're saying: start over completely. We're looking for the IDEAL step 0.

And then my response was too much of a "here's my solution" rather than a true design exploration. They want me to go back further — to question assumptions, to think about what step 0 even means when we consider all the dimensions they listed.

Let me think more fundamentally:

**What is "step 0"?** It's the thing you do BEFORE you have anything. Before you have a dotfiles repo. Before you have tools installed. Before you even know what machine you're on.

But they want it to consider:
- Versioning (of what? the environment itself, the configs, the prompts?)
- Gists (for sharing snippets)
- Profiles (different contexts)
- Multi-platform
- Portability
- Link generation
- README versioning
- Prompt plans
- Automation
- Cross-agentic (works across Claude, GPT, Reasonix, etc.)
- Platform independency
- Easy re-use
- AI cross-check
- Always review and brainstorm

So step 0 isn't just a bootstrap script. It's the **meta-system** — the system that bootstraps the system that manages the environment.

Let me think about this as layers:

**Layer 0**: The idea/design — what are we trying to achieve?
**Layer 1**: The discovery — what's the current state?
**Layer 2**: The bootstrap — how do we get from nothing to functional?
**Layer 3**: The maintenance — how do we keep it healthy?
**Layer 4**: The evolution — how do we improve it?

The user wants step 0 to be the **seed** — something so minimal and universal that it can bootstrap everything else, but also so well-designed that it's versionable, portable, AI-readable, and cross-platform.

I think the user is pushing back on me jumping to "here's a 7-file dotfiles repo" without first thinking through what the actual requirements and constraints are.

Let me approach this differently — more like a true design exploration from zero. I should ask questions and think out loud, not present solutions.

Actually wait — they said "spatne zaciname s navrhem od 0" — "we're starting the design from 0 wrong." They want me to go EVEN MORE fundamental.

Let me think about what the real question is:

The fundamental tension: you have NO environment, you need an environment, but the environment needs to be versionable, portable, AI-readable, and cross-platform. How do you bootstrap this without a bootstrap paradox?

Step 0 is the minimal seed that:
1. Can be delivered via the simplest possible mechanism (a single URL, a single file)
2. Discovers everything about the current state
3. Establishes versioning immediately (git init + remote)
4. Is self-documenting
5. Is AI-readable (structured, commented, with a clear "contract")
6. Works on any platform
7. Creates profiles automatically
8. Is idempotent and re-runnable

But more importantly — the user wants me to think out loud about the DESIGN, not jump to implementation. They want a brainstorm.

Let me structure this as a design exploration. I'll ask clarifying questions rather than prescribing.

</details>

## Od nuly — hledání ideálního KROKU 0

Dobře, zahodil jsem všechno. Začínám od absolutní nuly.

Místo "tady je 7 souborů" se ptám:

---

### Co je KROK 0?

Je to **jediná akce**, kterou provedeš na holém stroji.  
Po ní už nic není "holý stroj" — máš **identitu**, **verzi**, **kontext**.

Ale co přesně to znamená? Rozeberme to po vrstvách:

---

### Vrstva 1 — Co se musí stát při KROKU 0

| Nutnost | Otázka |
|---|---|
| **Spustitelnost** | Jak to spustíš, když nemáš nic? (URL do PowerShellu? Stažený ZIP? USB klíč?) |
| **Discovery** | Jak to pozná, na jakém je stroji? (work/home/lab/VM/cloud?) |
| **Identita** | Kdo jsi na tomhle stroji? (osobní git email × firemní login?) |
| **Verzování** | Kam se uloží samotný setup? (Git repo? Kde?) |
| **První konfig** | Co je absolutní minimum, aby se dalo pracovat? (git, shell, editor?) |

---

### Vrstva 2 — Co musí přežít

| Požadavek | Co to znamená pro KROK 0 |
|---|---|
| **Multiplatformní** | Musí fungovat na Windows, Linux, macOS — ale KROK 0 je PŘED instalací čehokoliv. Jak? |
| **Portabilita** | Musí fungovat i když nemám admin práva (firemní PC). Co pak? |
| **Verzovatelné** | Samotný setup musí být v Gitu. Ale Git ještě nemusí být nainstalovaný. Chicken-and-egg. |
| **AI-čitelné** | Až to sem pošlu já (AI agent), musím to pochopit do 10 sekund. Jaká struktura to zajistí? |
| **Znovupoužitelné** | Stejný KROK 0 pro 3 různé stroje — co se liší a co je společné? |
| **Profily** | WORK vs HOME — přepíná se automaticky, nebo ručně? |

---

### Vrstva 3 — Otevřené otázky (neřeším, ptám se)

1. **Spouštěcí mechanismus**:  
   `curl | pwsh` předpokládá curl + pwsh. Na holém Windows 10/11 je `curl.exe` (alias) a `powershell.exe`, ne `pwsh`.  
   → Má být KROK 0 **jeden .ps1 soubor**, který jde spustit i v PowerShell 5.1?

2. **Verzování před Gitem**:  
   KROK 0 vygeneruje soubory. Ale kam je uložit, když Git ještě není?  
   → Má KROK 0 vytvořit **lokální git repozitář okamžitě** (`git init`), i bez remote? A remote přidat až později? Nebo uložit jako **gist** a pak z něj udělat repo?

3. **Profil jako data, ne kód**:  
   `profile.ps1` s logikou × `profile.json` s daty.  
   → Když je profil JSON, může ho číst cokoliv (AI, bash, Python). Když je to .ps1, je spustitelný, ale méně přenositelný. Co je správně pro KROK 0?

4. **Minimální vs. maximální**:  
   KROK 0 může být jen "zapiš pár proměnných do souboru", nebo "nainstaluj winget, git, nastav HOME, naklonuj dotfiles".  
   → Kde je hranice mezi "objevováním" a "instalováním"?

5. **Cross-agentic**:  
   Máš tu mě. Zítra tu může být Claude, GPT, nebo lokální model.  
   → Co musí KROK 0 vyprodukovat, aby **jakýkoliv** AI agent okamžitě pochopil stav a mohl pokračovat?

6. **Review loop**:  
   Chceš, aby AI vždycky přezkoumala výstup, navrhla zlepšení, a KROK 0 se iterativně vylepšoval.  
   → Má KROK 0 produkovat i **metadata pro AI** (např. "tady je 5 věcí ke zlepšení")?

---

### Místo odpovědi — chci tvůj vstup

Než vymyslím další "řešení", potřebuju vědět:

> **Tool · `ask_choice`**

```json
{"question": "Který přístup ke KROKU 0 ti dává největší smysl?", "options": [{"id":"minimal-seed","title":"Minimální seed — jeden soubor, žádné závislosti","summary":"Čistý .ps1 (PowerShell 5.1), bez curl, bez gitu. Udělá jen discovery → zapíše JSON → vytiskne instrukce pro další krok. Git, profily, konfigy až v KROKU 1."},{"id":"git-first","title":"Git-first bootstrap — první věc je repo","summary":"KROK 0 = nainstalovat git (winget/apt/brew) → git init → commitnout první discovery → pak profil, repair, test. Repo je zdroj pravdy od prvního okamžiku."},{"id":"gist-seed","title":"Gist jako seed — jednorázový URL bootstrap","summary":"KROK 0 = jeden gist (RAW URL). Spustíš → objeví → nabídne vytvoření repa NEBO gistu. Funguje i bez lokálního gitu."},{"id":"ai-contract","title":"AI-kontrakt — struktura, ne skript","summary":"KROK 0 nedefinuju jako kód, ale jako KONTRAKT (JSON schéma + Markdown). Každý AI agent si podle něj vygeneruje skript na míru. Platformně nezávislé."}]}
```

```
user picked: gist-seed
```

<details>
<summary>Reasoning</summary>

The user chose "gist-seed" — a gist as the seed, a single URL bootstrap. This makes a lot of sense: a gist is versioned by nature, has a raw URL, and can be the initial seed before any git repo exists.

Now I need to design this properly. Let me think through what the gist-seed approach means:

**Gist as KROK 0:**
- One GitHub Gist containing the bootstrap file(s)
- Raw URL → can be invoked via `irm | iex` (PowerShell) or `curl | sh` (Unix)
- The gist IS versioned (gists have revision history)
- The gist can evolve into a full repo when ready
- Works even without local git installed

**The flow:**
1. User opens PowerShell, runs: `irm https://gist.githubusercontent.com/.../raw/bootstrap.ps1 | iex`
2. Script discovers everything (like we designed before)
3. Script asks: "Want me to create a dotfiles repo? Or keep this as a gist?"
4. If repo: `git init` in `~/dev/dotfiles`, commit the discovery, set remote
5. If gist: update the existing gist with discovery results, generate README
6. Either way: generates profiles, repair scripts, test scripts
7. Output: everything is versioned from moment zero

**The gist itself contains:**
- `bootstrap.ps1` — the main entry point (PowerShell 5.1 compatible)
- `profile.ps1` — auto-detection
- `profiles/` — profile JSON files
- Generated after first run: discovery JSON, README, repair/test scripts

Now let me think about what the user wants NEXT. They chose "gist-seed" from the design exploration. Should I now generate the actual files?

I think the next step is to design the gist-seed architecture in detail, then ask if they want me to generate the actual code. Let me structure this as a clear design proposal.

Actually, the user said they want to iterate on the design. Let me present the gist-seed architecture clearly with all the dimensions they mentioned (versioning, gists, profiles, multiplatform, portability, link generation, README, cross-agentic, etc.) and show how each is addressed.

Then ask if they want me to generate the actual files.

</details>

## Gist-Seed — architektura KROKU 0

Dobrá volba. Gist jako seed dává smysl: je to **jediná URL**, je **verzovaný od prvního uložení** (každá revize má hash), **nepotřebuje lokální git**, a přitom z něj může kdykoliv vzniknout plnohodnotné repo.

Pojďme to rozebrat do hloubky — všech 10 dimenzí, které jsi zmínil.

---

## 1. Verzování — jak Gist řeší chicken-and-egg

```
PROBLÉM:  Chci verzovat setup, ale Git ještě nemám nainstalovaný.
ŘEŠENÍ:   Gist JE git repo (každý gist má .git). 
          KROK 0 = stáhnout gist → objevit → commitnout výsledek zpět.
```

**Tok verzí:**

```
Gist rev. 1 (seed)    →  bootstrap.ps1, profile.ps1, profiles/*.json
Gist rev. 2 (disco)   →  + discovery.json, README.md (vygenerované)
Gist rev. 3 (repair)  →  + repair.ps1, test.ps1, configs/*
Gist rev. N           →  migrace do plného repa (volitelné)
```

Každá revize = audit trail. Vždy se dá vrátit.

---

## 2. Gisty — co přesně v gistu žije a co ne

| V gistu (verzované) | Mimo gist (lokální / generované) |
|---|---|
| `bootstrap.ps1` — hlavní skript | `discovery-<hostname>.json` — výsledek objevu |
| `profile.ps1` — detekce stroje | `README.md` — generovaný rozcestník |
| `profiles/*.json` — definice profilů | Konfigy v `~/.config/` — symlinky na gist |
| `repair.ps1` — opravný skript | `.gitconfig` — symlink |
| `test.ps1` — testovací skript | SSH klíče (NIKDY v gistu) |
| `configs/` — šablony konfigů | |

---

## 3. Profily — jak to funguje

```
profiles/
├── base.json            ← Společné pro všechny (jazyk, editor, defaultní nástroje)
├── home.personal.json   ← Domácí PC (volné, plná práva, Windows 11 Pro)
├── home.lab.json        ← Domácí lab (VM, experimenty, WSL, Docker)
└── work.ppg.json        ← Firemní PPG (proxy, VPN, omezený PATH, žádný winget)
```

**Profil = JSON**, protože:

- AI ho přečte okamžitě (není to kód, je to deklarace)
- Je validovatelný (JSON Schema)
- Je slučitelný (base → override → finální)
- Bash, Python, PowerShell — všechny to parsují

**Merge logika** (`profile.ps1`):
```
base.json  →  home.personal.json  →  finální nastavení
(společné)    (přepisuje/extenduje)   (to co se aplikuje)
```

---

## 4. Multiplatformní — jeden gist, tři OS

`bootstrap.ps1` běží na:

| Platforma | Shell | Co se stane |
|---|---|---|
| **Windows 10/11** | `powershell.exe` (5.1) | Detekce, winget/scoop, `$env:USERPROFILE` |
| **Windows** | `pwsh.exe` (7+) | Plná funkčnost včetně `$IsWindows` |
| **Linux** | `pwsh` | `$IsLinux`, apt/dnf/pacman, `$HOME` |
| **macOS** | `pwsh` | `$IsMacOS`, brew, `$HOME` |

Větvení uvnitř skriptu:
```powershell
if ($IsWindows) {
    $homePath = $env:USERPROFILE
    $pkgManager = (Get-Command winget) ? "winget" : "scoop"
} elseif ($IsLinux) {
    $homePath = $env:HOME
    $pkgManager = (Get-Command apt) ? "apt" : "dnf"
}
```

PowerShell 5.1 na Windows funguje jako fallback — detekuje že je starý a doporučí upgrade na 7.

---

## 5. Portabilita — bez admin práv

Firemní PC (PPG): žádný admin, žádný winget, žádný scoop, možná blokované skripty.

**Co dělá KROK 0 na omezeném stroji:**

1. Zjistí omezení (GPO, ExecutionPolicy, Proxy, blokovaný PowerShell)
2. **Nepokouší se instalovat** — jen objeví a zapíše
3. Vygeneruje `workaround-<hostname>.md` s instrukcemi:
   - "Požádej IT o povolení ExecutionPolicy RemoteSigned"
   - "Nainstaluj Git portable na `D:\PortableApps\`"
   - "Nastav `HOME=D:\home` ručně"
4. Všechny cesty používají **relativní/portable** prefixy (`$HOME\bin`, ne `C:\Program Files\...`)

---

## 6. Link generation + README versioning

Po každém spuštění `bootstrap.ps1` se vygeneruje/aaktualizuje `README.md`:

```markdown
# Dotfiles — <hostname>
> Profil: **home.personal** | Vygenerováno: 2025-01-15 14:30

## Rychlé odkazy
- [Projekty](file:///C:/Users/jan/dev/projects/)
- [Konfigy](file:///C:/Users/jan/.config/)
- [Stažené](file:///C:/Users/jan/Downloads/)
- [Tento gist](https://gist.github.com/jan/abc123)

## Nástroje
| Nástroj | Verze | Cesta |
|---|---|---|
| git | 2.47.1 | C:\Program Files\Git\bin\git.exe |
| node | 22.12.0 | C:\Program Files\nodejs\node.exe |
...

## Zjištěné problémy
- [ ] `HOME` není nastaveno → spusť `./repair.ps1 -FixHome`
- [ ] OneDrive přesměrovává Documents → spusť `./repair.ps1 -FixOneDrive`
```

README je **živý dokument** — při každé změně se přegeneruje.

---

## 7. Cross-agentic — AI kontrakt

Každý soubor v gistu má **standardizovanou hlavičku**, kterou přečte jakýkoliv model:

```yaml
# === META ==========================================
# @file:      bootstrap.ps1
# @role:      Entry point — discovery + first setup
# @inputs:    none (self-contained)
# @outputs:   discovery-<hostname>.json, README.md
# @requires:  powershell.exe (5.1+) or pwsh (7+)
# @platform:  Windows, Linux, macOS
# @profiles:  base → {work.ppg, home.personal, home.lab}
# @next:      profile.ps1 → repair.ps1 → test.ps1
# @gist:      https://gist.github.com/<user>/<id>
# ===================================================
```

**AI agent (já, Claude, GPT, lokální model) z toho za 3 sekundy ví:**
- Co soubor dělá
- Jak ho spustit
- Co potřebuje
- Co produkuje
- Kam vede další krok

---

## 8. Easy re-use — stejný gist, různé stroje

```
Stroj A (domácí PC)      → gist → profile=home.personal → volný režim
Stroj B (PPG notebook)    → gist → profile=work.ppg      → omezený režim
Stroj C (domácí lab VM)   → gist → profile=home.lab      → experimentální
```

Jeden gist, tři profily. `profile.ps1` detekuje automaticky (doména, výrobce, hostname).  
Profil jde přepsat: `bootstrap.ps1 -Profile work.ppg`.

---

## 9. AI cross-check + brainstorm loop

Po každém spuštění `test.ps1` se vygeneruje `review-<timestamp>.json`:

```json
{
  "passed": 12,
  "failed": 3,
  "suggestions": [
    "PATH obsahuje 7 neexistujících cest — repair.ps1 je vyčistí",
    "git config user.email chybí — chceš nastavit?",
    "Windows Terminal settings.json nalezen — chceš verzovat?"
  ],
  "next_actions": [
    "./repair.ps1 -WhatIf",
    "git commit -am 'post-repair checkpoint'"
  ]
}
```

Tohle pošleš AI agentovi (mně, nebo komukoliv jinému) a on ti řekne: _"Vidím 3 problémy. Chceš je opravit?"_

---

## 10. Celý lifecycle

```
┌─────────────────────────────────────────────────┐
│  KROK 0: irm <gist-url> | iex                   │
│  ↓                                               │
│  Objev → profil → discovery.json                │
│  ↓                                               │
│  KROK 1: ./repair.ps1 -WhatIf (co by se změnilo) │
│  ↓                                               │
│  KROK 2: ./repair.ps1 -Force (aplikovat opravy)  │
│  ↓                                               │
│  KROK 3: ./test.ps1 (ověřit) + review.json      │
│  ↓                                               │
│  KROK 4: Pošli review.json AI → návrhy zlepšení  │
│  ↓                                               │
│  KROK 5: Aktualizuj gist/repo → cyklus se opakuje│
└─────────────────────────────────────────────────┘
```

---

## Chceš, abych teď vygeneroval samotné soubory?

Mám připravenou strukturu — můžu generovat:

1. `bootstrap.ps1` — hlavní seed skript
2. `profile.ps1` — auto-detekce profilu
3. `profiles/base.json` — společné nastavení
4. `profiles/home.personal.json` — domácí profil
5. `profiles/work.ppg.json` — firemní profil
6. `repair.ps1` — opravy s `-WhatIf`
7. `test.ps1` — testovací skript

Nebo chceš ještě něco doladit na návrhu?

---

### You

brainstiorm identita - Kdo jsi na tomhle stroji? (osobní git email × firemní login?) + dokonce - login

---

### Reasonix

<details>
<summary>Reasoning</summary>

The user wants to brainstorm the identity layer more deeply. They're asking: "Who are you on this machine?" — personal git email vs corporate login — and they're extending it to the actual login/authentication layer.

Let me think about this systematically. Identity in a dev environment context has multiple dimensions:

1. **OS login identity** — the Windows user account (local vs domain, Microsoft account vs local)
2. **Git identity** — user.name and user.email per repo or global
3. **SSH identity** — which SSH keys, which GitHub/GitLab accounts
4. **Package manager identity** — npm, docker, pip logins
5. **Cloud/API identity** — Azure, AWS, GCP credentials
6. **Email identity** — personal vs work email
7. **Browser profiles** — work vs personal
8. **GitHub/GitLab accounts** — personal vs work organization

The core tension: on a work machine (PPG domain), you might be logged in as `PPG\jan.novak`, but you also have a personal GitHub account `jannovak` and a personal email. On a home machine, you're `jan@outlook.com` (Microsoft account) but you might also need to access PPG resources via VPN.

So "who are you on this machine" is not a single answer — it's a **matrix** of identities that need to coexist, and some are forced by the machine context (domain login) while others are chosen.

Let me structure this as a brainstorm.

</details>

## Identita — víc než "osobní × firemní"

Klasická chyba: ptát se "osobní, nebo firemní?" jako by to byla binární volba. Ve skutečnosti je identita **matice** — vrství se na sobě a každá vrstva se přepíná jinak.

Pojďme ji rozebrat.

---

## Vrstvy identity na jednom stroji

```
┌──────────────────────────────────────────────────┐
│  VRSTVA 1 — OS login (kdo sedí u klávesnice)     │
│  → Windows: lokální účet, Microsoft účet, doména │
│  → Linux/macOS: lokální, LDAP, MDM               │
│  → TOTO NEJDE ZMĚNIT ZA BĚHU — je to dané strojem│
├──────────────────────────────────────────────────┤
│  VRSTVA 2 — Git identita (kdo commituje)          │
│  → user.name, user.email                          │
│  → Globální × per-repo × per-folder (includeIf)   │
│  → TOTO SE PŘEPÍNÁ PODLE SLOŽKY                   │
├──────────────────────────────────────────────────┤
│  VRSTVA 3 — SSH klíče (ke komu se připojuješ)     │
│  → id_ed25519 (osobní GitHub)                     │
│  → id_ed25519_ppg (firemní GitLab/Bitbucket)      │
│  → SSH config s Host matchingem                   │
├──────────────────────────────────────────────────┤
│  VRSTVA 4 — Package registry (kdo publikuje)      │
│  → npm login, pip, docker, cargo, nuget           │
│  → Často vázané na aktuální adresář/projekt       │
├──────────────────────────────────────────────────┤
│  VRSTVA 5 — Cloud/API (kdo platí)                 │
│  → az login, aws configure, gcloud auth            │
│  → Může být více profilů (--profile)              │
├──────────────────────────────────────────────────┤
│  VRSTVA 6 — Browser (kdo brouzdá)                 │
│  → Work profil × osobní profil                    │
│  → Uložená hesla, cookies, session                │
├──────────────────────────────────────────────────┤
│  VRSTVA 7 — AI agent (kdo se ptá)                 │
│  → Který model, jaký kontext, jaká paměť          │
│  → Může se lišit podle projektu                   │
└──────────────────────────────────────────────────┘
```

---

## Problém: tyhle vrstvy spolu nesouhlasí

Reálný scénář — **firemní notebook PPG**:

| Vrstva | Kdo jsem |
|---|---|
| OS login | `PPG\jan.novak` (doménový účet, spravovaný IT) |
| Git globálně | `Jan Novak <jan.novak@ppg.com>` (nastaveno GPO) |
| Git v `~/dev/projects/osobni/` | **MĚLO BY BÝT** `Jan Novak <jan@novak.cz>` |
| SSH klíče | Potřebuju OBA — firemní GitLab i osobní GitHub |
| npm | Osobní účet, ale za firemním proxy |
| Azure CLI | `jan.novak@ppg.com` (SSO, Conditional Access) |
| Browser | Edge (firemní profil) + Chrome (osobní profil) |

A teď to samé na **domácím PC**:

| Vrstva | Kdo jsem |
|---|---|
| OS login | `jan@outlook.com` (Microsoft účet) |
| Git globálně | `Jan Novak <jan@novak.cz>` |
| Git v `~/dev/projects/ppg/` | **MĚLO BY BÝT** `Jan Novak <jan.novak@ppg.com>` |
| SSH klíče | Primárně osobní GitHub, firemní přes VPN |
| Azure CLI | Musí se přihlásit přes Conditional Access (mimo doménu) |

---

## Řešení: Git `includeIf` jako páteř

Git od verze 2.13+ umí podmíněné includy podle cesty:

```ini
# ~/.gitconfig (společné)
[init]
    defaultBranch = main
[core]
    autocrlf = input
    editor = code --wait

# Osobní projekty → osobní identita
[includeIf "gitdir:~/dev/projects/osobni/"]
    path = ~/.gitconfig-personal

# PPG projekty → firemní identita
[includeIf "gitdir:~/dev/projects/ppg/"]
    path = ~/.gitconfig-ppg
```

```ini
# ~/.gitconfig-personal
[user]
    name = Jan Novak
    email = jan@novak.cz
[github]
    user = jannovak
```

```ini
# ~/.gitconfig-ppg
[user]
    name = Jan Novak
    email = jan.novak@ppg.com
[http]
    proxy = http://proxy.ppg.com:8080
```

**Tohle je klíčový insight:** identita se nevolí podle toho, na jakém jsi stroji. Volí se podle toho, **v jaké složce pracuješ**.

---

## SSH — `~/.ssh/config` s aliasy

```
# Osobní GitHub
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519

# Firemní GitLab (PPG)
Host gitlab.ppg.com
    HostName gitlab.internal.ppg.com
    User git
    IdentityFile ~/.ssh/id_ed25519_ppg
    ProxyCommand connect -H proxy.ppg.com:8080 %h %p
```

AI agent (nebo `repair.ps1`) tohle umí:
- Zjistit, jestli `~/.ssh/id_ed25519*` existují
- Zkontrolovat, jestli `~/.ssh/config` pokrývá všechny profily
- Nabídnout vygenerování chybějících klíčů

---

## OS login — co s ním jde a nejde dělat

| Co | Možné? |
|---|---|
| **Zjistit** login (kdo jsem) | `whoami`, `$env:USERNAME`, `$env:USERDOMAIN` |
| **Změnit** login (přepnout účet) | ❌ Vyžaduje logout / runas |
| **Vytvořit alias** pro Git | ✅ `includeIf` podle složky |
| **Použít jiný klíč** pro SSH | ✅ `ssh -i`, config `IdentityFile` |
| **Použít runas** pro jednorázové příkazy | ✅ `runas /user:ppg\jan.novak cmd` |
| **WSL/Linux** — su/sudo | ✅ Na vlastním stroji |

**Závěr:** OS login je pevně daný a nemá smysl s ním bojovat. Místo toho se všechny ostatní vrstvy přizpůsobí **kontextu** (adresář, projekt, profil).

---

## Návrh: `identity.json` jako součást profilu

```json
{
  "profile": "work.ppg",
  "os": {
    "detected_login": "PPG\\jan.novak",
    "domain": "PPG",
    "is_domain_joined": true
  },
  "git": {
    "default": {
      "name": "Jan Novak",
      "email": "jan.novak@ppg.com"
    },
    "overrides": {
      "~/dev/projects/osobni/": {
        "name": "Jan Novak",
        "email": "jan@novak.cz"
      }
    }
  },
  "ssh": {
    "keys": [
      { "file": "~/.ssh/id_ed25519", "comment": "jan@novak.cz", "for": "github.com" },
      { "file": "~/.ssh/id_ed25519_ppg", "comment": "jan.novak@ppg.com", "for": "gitlab.ppg.com" }
    ]
  },
  "registries": {
    "npm": { "user": "jannovak", "registry": "https://registry.npmjs.org" }
  },
  "cloud": {
    "azure": { "tenant": "ppg.com", "login_method": "devicecode" }
  },
  "browser": {
    "work_profile": "Edge",
    "personal_profile": "Chrome"
  }
}
```

Tohle je **deklarativní** a přečte to:
- `repair.ps1` → aplikuje do `.gitconfig`, `.ssh/config`, `.npmrc`
- `test.ps1` → zkontroluje, jestli to sedí s realitou
- AI agent → ví přesně, kdo jsi v jakém kontextu

---

## Co KROK 0 udělá s identitou

1. Zjistí OS login (`whoami`, `$env:USERDOMAIN`)
2. Zkusí přečíst existující `.gitconfig` (jestli už něco je)
3. Najde existující SSH klíče (`~/.ssh/id_*`)
4. **Zeptá se na minimum:**
   - Osobní email (pro `home.personal`)
   - Firemní email (pro `work.ppg`)
   - GitHub/GitLab usernames
5. Vygeneruje `identity.json` do profilu
6. Nabídne: _"Chceš nastavit Git includeIf pro `~/dev/projects/osobni/` a `~/dev/projects/ppg/`?"_

A hlavně: **identity.json nikdy neobsahuje tajemství** (hesla, tokeny). Jen odkazy na ně (`~/.ssh/id_ed25519`, `~/.npmrc`).

---

Chceš tenhle identity model rovnou zapracovat do souborů, nebo ještě probereme nějakou vrstvu?

---

### You

zastav u kroku 0, grilluj me 

Gist-Seed — architektura KROKU 0
Dobrá volba. Gist jako seed dává smysl: je to jediná URL, je verzovaný od prvního uložení (každá revize má hash), nepotřebuje lokální git, a přitom z něj může kdykoliv vzniknout plnohodnotné repo.

---

### Reasonix

<details>
<summary>Reasoning</summary>

The user wants me to stop at Step 0 and "grill" them — meaning they want me to challenge, question, and stress-test the Gist-Seed architecture. They want me to poke holes in it, find the flaws, the edge cases, the things that will break. They quoted the Gist-Seed architecture description and want me to grill it.

Let me think about all the problems with the Gist-Seed approach:

1. **Gist requires a GitHub account** — What if you don't have one yet? What if you don't want your dotfiles on GitHub?
2. **Gist requires internet** — What about air-gapped machines? Firewall blocking GitHub?
3. **Gist authentication** — To update a gist (rev 2, 3...), you need a GitHub token. How do you get that on a fresh machine?
4. **PowerShell execution policy** — On a locked-down corporate machine, `irm | iex` might be blocked.
5. **Single file limitation** — A gist can be multiple files, but the URL to raw content is per-file. The "single URL" bootstrap idea gets complicated with multiple files.
6. **Privacy** — Discovery data in a gist? Even a secret gist is "anyone with the link can see it." Discovery contains hostname, username, paths, tool versions — potential info leak.
7. **Gist API rate limiting** — For automated updates.
8. **Gist ownership** — If it's created from bootstrap, who owns it? The user must be logged in.
9. **What if GitHub is blocked?** — Corporate firewall, China, etc.
10. **Revision history is linear and limited** — Gist revisions are not branches.
11. **No CI/CD** — Unlike a full repo, gists don't have GitHub Actions.
12. **The "gist IS a git repo" claim** — Yes, but it's hidden. Most users don't know how to clone/push to it. It's git but not ergonomic.
13. **Multi-file bootstrap** — If bootstrap.ps1 is one file, but it needs profiles/*.json, how do you get them? The seed needs to be self-contained OR download subsequent files.
14. **The "download from gist" step itself** — `irm <gist-url> | iex` only gets ONE file (the raw URL). To get the whole gist as a zip, you need a different URL.
15. **Gist vs repo migration path** — When you outgrow the gist, how painful is the migration?
16. **Offline / cache** — What if you want to re-run bootstrap and GitHub is down?
17. **Version pinning** — How do you pin a specific version of the bootstrap? Gist revisions have SHA hashes, but the raw URL always gives you the latest.
18. **Discovery data in the gist** — Do you really want machine-specific discovery JSON committed back to the shared gist? That pollutes it when you use the same gist across 3 machines.
19. **What about non-GitHub users?** — GitLab snippets? Bitbucket? Self-hosted Gitea?
20. **The "single URL" promise** — Actually, `irm <url> | iex` is TWO commands. And `irm` is PowerShell 5.1+ only. On Linux, you'd need `curl | pwsh`.

Let me structure these as a grill session — sharp questions, not just a list.

</details>

## 🔥 GRILL — Gist-Seed pod palbou

Žádné šetření. Tady je 20 děr, kterýma to teče.

---

## BLOK 1 — GitHub jako single point of failure

**1. Co když nemám GitHub účet?**
Gist vyžaduje účet. KROK 0 = vytvořit si GitHub účet? To není KROK 0, to je KROK -1. A co když nechci, aby moje dotfiles žily na cizím serveru?

**2. Co když je GitHub za firewallem?**
PPG, banky, armáda — GitHub často blokovaný. Nebo povolený jen přes proxy s MITM certifikátem, který PowerShell nesežere.

**3. Co když je GitHub down?**
Spustíš KROK 0 na novém stroji, `irm` selže. Jsi mrtvý. Žádný fallback. Kde je offline kopie?

**4. Co když nechci veřejný gist, ale secret gist nestačí?**
Secret gist = "kdokoliv s URL". Discovery JSON obsahuje: hostname, username, cesty, verze nástrojů, doménu, VPN klienty. To je **recon sen** pro útočníka. Dáváš to na URL, kterou "nikdo neuhodne"?

---

## BLOK 2 — Technický rozpor "jediné URL"

**5. Gist ≠ jeden soubor.**
Gist je repo s více soubory. `irm https://gist.githubusercontent.com/.../raw/.../bootstrap.ps1 | iex` stáhne **jen** bootstrap.ps1. Ne profily. Ne repair. Takže bootstrap.ps1 musí uvnitř obsahovat VŠECHNO, nebo si to stahovat sám. Už to není "jeden URL seed".

**6. Self-contained bootstrap = monolitický blob.**
Když nacpeš všechny profily, repair, test do jednoho .ps1, máš 2000 řádků kódu v jednom souboru. Jak to verzuješ? Jak to reviewuješ? Kde je "snadná AI čitelnost", když je to jeden nerozlišitelný blob?

**7. `irm | iex` je dvě operace, ne jedna.**
A `iex` (Invoke-Expression) je na firemních strojích často blokovaný ExecutionPolicy. KROK 0 selže na prvním řádku. Co teď?

---

## BLOK 3 — Zpětný zápis

**8. Jak se gist aktualizuje?**
KROK 0 chce zapsat `discovery-<hostname>.json` zpět do gistu. To vyžaduje GitHub token s oprávněním `gist`. Kde ho vezmeš na holém stroji? Budeš ho opisovat z mobilu? Ukládat do `~/.github-token` před spuštěním?

**9. Tři stroje → tři discovery → jeden gist?**
Gist je **jeden**. Když do něj tři stroje pushují svoje `discovery-*.json`, vznikne chaos. Který discovery patří kterému stroji? Jak to merguješ? Gist nemá větve.

**10. Gist API rate limit.**
Neautentikované požadavky: 60/hod. Autentikované: 5000/hod. Ale bootstrap.ps1 možná volá API vícenásobně (čtení + zápis + aktualizace). Na pomalém VPN to může být problém.

---

## BLOK 4 — Multiplatformní iluze

**11. `irm` na Linuxu neexistuje.**
`Invoke-RestMethod` je PowerShell cmdlet. Na Linuxu nemáš PowerShell, dokud ho nenainstaluješ. Takže: `curl | pwsh` → ale `pwsh` taky není. Klasický chicken-and-egg.

**12. `powershell.exe` na Windows 10/11 má `irm`, ale…**
PowerShell 5.1 má `irm`, ale neumí `$IsWindows`/`$IsLinux`. A TLS 1.2 není default. `[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12` — musíš to dát do skriptu, jinak `irm` na starších Windows selže.

**13. macOS — stejný problém jako Linux.**
Žádný `pwsh` předinstalovaný. `curl | bash`
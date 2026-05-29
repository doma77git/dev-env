# PowerShell profile — loaded on every pwsh start
# Načítá se při každém spuštění pwsh

# Starship prompt (if installed)
if (Get-Command starship -ErrorAction SilentlyContinue) {
    Invoke-Expression (&starship init powershell)
}

# Aliases / zástupky
Set-Alias -Name g   -Value git
Set-Alias -Name gh  -Value gh
Set-Alias -Name vim -Value nvim -ErrorAction SilentlyContinue

# Path / cesty
$env:PATH += ";$env:HOME\bin"

# Functions
function dev { cd ~/dev/projects }
function dot { cd ~/.dev-env/repo }
function reload { . $PROFILE }

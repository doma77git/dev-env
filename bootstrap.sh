#!/usr/bin/env bash
# === bootstrap.sh =============================================
# URL:    https://gist.github.com/doma77git/2f489d9ce5e7e0ff75b17cbe8011bbb5
# ROLE:   Linux/WSL entry — orchestrator (00→30→10→20→40→50)
#         Detekce prostředí + clone + profil + setup
# RUN:    curl -fsSL <url> | bash                              (Linux/WSL)
#         DEV_ENV_WHATIF=1 curl -fsSL <url> | bash             (dry-run)
# PARTNER: bootstrap.ps1 — irm <url> | iex                      (Windows)
# PATTERN: curl -fsSL <url>/bootstrap.sh | bash (dotfiles standard)
# ==============================================================
set -euo pipefail

REPO_URL="https://github.com/doma77git/dev-env"
ENV_DIR="$HOME/.dev-env"
REPO_DIR="$ENV_DIR/repo"
CONFIG_DIR="$ENV_DIR/config"
DRY_RUN="${DEV_ENV_WHATIF:-0}"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
NC='\033[0m'
BOLD='\033[1m'

header() { echo -e "\n${CYAN}╔══════════════════════════════════════════╗${NC}"; echo -e "${CYAN}║  $1${NC}"; echo -e "${CYAN}╚══════════════════════════════════════════╝${NC}"; }
ok()    { echo -e "  ${GREEN}✅${NC}  $1"; }
warn()  { echo -e "  ${YELLOW}⚠️${NC}   $1"; }
err()   { echo -e "  ${RED}❌${NC}  $1"; }
info()  { echo -e "  ${GRAY}ℹ${NC}   $1"; }
whatif() { if [ "$DRY_RUN" = "1" ]; then echo -e "  ${GRAY}[WHATIF]${NC} Would: $1"; return 0; else return 1; fi; }

if [ "$DRY_RUN" = "1" ]; then
    echo -e "${YELLOW}>>> DRY-RUN MODE (DEV_ENV_WHATIF=1) — no changes will be made${NC}"
fi

# ═══════════════════════════════════════════════════════════════
# PHASE 00 — CORE CHECK
# ═══════════════════════════════════════════════════════════════
header "PHASE 00 — CORE CHECK"

# Bash version
BASH_VER="${BASH_VERSINFO[0]}.${BASH_VERSINFO[1]}"
ok "Bash $BASH_VER"

# Git
if command -v git &>/dev/null; then
    ok "Git: $(git --version 2>&1 | head -1)"
    HAS_GIT=1
else
    err "Git not found"
    echo "  Install: sudo apt install git  |  brew install git"
    HAS_GIT=0
fi

# Connectivity
if command -v curl &>/dev/null; then
    if curl -s --connect-timeout 5 https://github.com >/dev/null 2>&1; then
        ok "github.com reachable"
    else
        warn "github.com unreachable — clone will fail"
    fi
else
    warn "curl not found — connectivity check skipped"
fi

# ═══════════════════════════════════════════════════════════════
# PHASE 30 — CLONE
# ═══════════════════════════════════════════════════════════════
header "PHASE 30 — REPOSITORY CLONE"
if [ "$HAS_GIT" = "1" ]; then
    if whatif "git clone/pull $REPO_URL → $REPO_DIR"; then
        : # dry-run, skip
    elif [ -d "$REPO_DIR/.git" ]; then
        echo "  Repo exists — pulling latest ..."
        git -C "$REPO_DIR" pull 2>&1 | sed 's/^/  /' || warn "Pull had issues — checking out"
        # Fix broken repo: reset scripts/
        if [ ! -f "$REPO_DIR/scripts/10-detect.ps1" ]; then
            warn "Broken repo detected — resetting scripts/"
            git -C "$REPO_DIR" checkout HEAD -- scripts/ 2>/dev/null || true
            git -C "$REPO_DIR" checkout HEAD -- bootstrap.sh 2>/dev/null || true
        fi
        ok "Pull complete"
    else
        echo "  Cloning $REPO_URL ..."
        mkdir -p "$ENV_DIR"
        git clone -b master "$REPO_URL" "$REPO_DIR" 2>&1 | sed 's/^/  /'
        ok "Clone complete"
    fi
    HAS_REPO=1
    echo "  Repo: $REPO_DIR"
else
    echo "  Git not installed — skipping clone"
    HAS_REPO=0
fi

# ═══════════════════════════════════════════════════════════════
# PHASE 10 — DETECT (inline, self-contained)
# ═══════════════════════════════════════════════════════════════
header "PHASE 10 — ENVIRONMENT DETECT"

mkdir -p "$ENV_DIR"

# Fingerprint
HOSTNAME=$(hostname)
USERNAME=$(whoami)
DOMAIN="localhost"
if [ -f /etc/resolv.conf ]; then
    SEARCH=$(grep -m1 '^search' /etc/resolv.conf 2>/dev/null | awk '{print $2}' || echo "")
    [ -n "$SEARCH" ] && DOMAIN="$SEARCH"
fi
FINGERPRINT=$(echo -n "$HOSTNAME|$USERNAME|$DOMAIN" | sha256sum | cut -d' ' -f1)

# OS detection
if [ -f /etc/os-release ]; then
    OS_CAPTION=$(grep PRETTY_NAME /etc/os-release | cut -d= -f2 | tr -d '"')
else
    OS_CAPTION="$(uname -s) $(uname -r)"
fi
KERNEL=$(uname -r)
ARCH=$(uname -m)

# WSL detection
IS_WSL=0
if grep -qi microsoft /proc/version 2>/dev/null; then
    IS_WSL=1
    OS_CAPTION="$OS_CAPTION (WSL)"
fi

# Tools detection
tool_ver() {
    local t=$1
    if CMD=$(command -v "$t" 2>/dev/null); then
        local ver
        ver=$( ("$t" --version 2>/dev/null || "$t" -v 2>/dev/null || echo "?") | head -1 | tr -d '\n' | tr -d '\r' )
        echo "    \"$t\": \"$ver | $CMD\","
    else
        echo "    \"$t\": null,"
    fi
}

TOOLS_JSON=""
for t in git node python code docker gh curl 7z nvim pip npm make gcc; do
    TOOLS_JSON="$TOOLS_JSON$(tool_ver "$t")\n"
done

# PATH
PATH_COUNT=$(echo "$PATH" | tr ':' '\n' | grep -c .)

# Corporate signals
IN_DOMAIN="false"
PROXY_DETECTED="false"
if [ -n "${http_proxy:-}" ] || [ -n "${HTTP_PROXY:-}" ] || [ -n "${https_proxy:-}" ] || [ -n "${HTTPS_PROXY:-}" ]; then
    PROXY_DETECTED="true"
fi

# Status: compare with previous run
STATUS="new"
MACHINES_FILE="$ENV_DIR/machines.json"
if [ -f "$MACHINES_FILE" ]; then
    PREV_FP=$(grep -o '"fingerprint"[[:space:]]*:[[:space:]]*"[^"]*"' "$MACHINES_FILE" | tail -1 | cut -d'"' -f4 || echo "")
    PREV_OS=$(grep -o '"caption"[[:space:]]*:[[:space:]]*"[^"]*"' "$MACHINES_FILE" | tail -1 | cut -d'"' -f4 || echo "")
    if [ "$PREV_FP" = "$FINGERPRINT" ]; then
        if [ "$PREV_OS" = "$OS_CAPTION" ]; then
            STATUS="same"
        else
            STATUS="os-changed"
        fi
    fi
fi

echo "  fingerprint: ${FINGERPRINT:0:8}..."
echo "  OS: $OS_CAPTION (kernel $KERNEL, $ARCH)"

# ═══════════════════════════════════════════════════════════════
# PHASE 20 — REPORT
# ═══════════════════════════════════════════════════════════════
header "PHASE 20 — INVENTORY REPORT"

STATUS_ICON="🔴"
[ "$STATUS" = "same" ] && STATUS_ICON="🟢"
[ "$STATUS" = "os-changed" ] && STATUS_ICON="🟠"

REPORT_FILE="$ENV_DIR/report-$(date -u +%Y-%m-%d-%H%M%S).json"

cat > "$REPORT_FILE" << INNEREOF
{
  "meta": {
    "bootstrap": "1.1.0",
    "at": "$(date -u +%Y-%m-%dT%H:%M:%S)",
    "repo": "$REPO_URL",
    "platform": "linux",
    "wsl": $IS_WSL
  },
  "status": "$STATUS",
  "fingerprint": "$FINGERPRINT",
  "hostname": "$HOSTNAME",
  "username": "$USERNAME",
  "os": {
    "caption": "$OS_CAPTION",
    "kernel": "$KERNEL",
    "arch": "$ARCH"
  },
  "tools": {
$(echo -e "$TOOLS_JSON" | sed '$ s/,$//')
  },
  "path": {
    "count": $PATH_COUNT,
    "errors": []
  },
  "corporate": {
    "domainJoined": $IN_DOMAIN,
    "proxyDetected": $PROXY_DETECTED
  },
  "changes": []
}
INNEREOF

# Append to machines.json
if [ -f "$MACHINES_FILE" ]; then
    # Remove trailing ] and append
    head -n -1 "$MACHINES_FILE" > "${MACHINES_FILE}.tmp"
    echo "  ," >> "${MACHINES_FILE}.tmp"
    cat "$REPORT_FILE" >> "${MACHINES_FILE}.tmp"
    echo "]" >> "${MACHINES_FILE}.tmp"
    mv "${MACHINES_FILE}.tmp" "$MACHINES_FILE"
else
    echo "[" > "$MACHINES_FILE"
    cat "$REPORT_FILE" >> "$MACHINES_FILE"
    echo "]" >> "$MACHINES_FILE"
fi

echo "  $STATUS_ICON  $STATUS"
echo "  REPO : $REPO_URL"
echo "  RPT  : $REPORT_FILE"

# ═══════════════════════════════════════════════════════════════
# PHASE 40 — PROFILE DETECTION
# ═══════════════════════════════════════════════════════════════
header "PHASE 40 — PROFILE & IDENTITY"

# Auto-detect profile
PROFILE="home"
PROFILE_ICON="🏠"
PROFILE_REASON="default — no corporate signals"

# Server detection (headless)
if echo "$OS_CAPTION" | grep -qi "server"; then
    PROFILE="server"
    PROFILE_ICON="🖳"
    PROFILE_REASON="server OS detected"
# WSL = lab
elif [ "$IS_WSL" = "1" ]; then
    PROFILE="lab"
    PROFILE_ICON="🧪"
    PROFILE_REASON="WSL environment"
# Corporate proxy
elif [ "$PROXY_DETECTED" = "true" ]; then
    PROFILE="work"
    PROFILE_ICON="🏢"
    PROFILE_REASON="corporate proxy detected"
# VM detection
elif grep -qi "vmware\|virtualbox\|qemu\|xen" /proc/cpuinfo 2>/dev/null; then
    PROFILE="lab"
    PROFILE_ICON="🧪"
    PROFILE_REASON="VM detected"
# Domain search (corporate DNS)
elif [ "$DOMAIN" != "localhost" ] && [ -n "$DOMAIN" ]; then
    PROFILE="work"
    PROFILE_ICON="🏢"
    PROFILE_REASON="corporate domain: $DOMAIN"
fi

# Check saved profile
if [ -f "$CONFIG_DIR/profile.json" ]; then
    SAVED=$(grep -o '"profile"[[:space:]]*:[[:space:]]*"[^"]*"' "$CONFIG_DIR/profile.json" | cut -d'"' -f4 || echo "")
    if [ -n "$SAVED" ]; then
        PROFILE="$SAVED"
        PROFILE_REASON="saved (previous run)"
    fi
fi

# Identity detection
GIT_NAME=""
GIT_EMAIL=""
IDENTITY_SOURCE="placeholder"
if command -v git &>/dev/null; then
    GIT_NAME=$(git config --global user.name 2>/dev/null || echo "")
    GIT_EMAIL=$(git config --global user.email 2>/dev/null || echo "")
    if [ -n "$GIT_NAME" ] && [ -n "$GIT_EMAIL" ]; then
        IDENTITY_SOURCE="git-config"
    fi
fi
if [ -z "$GIT_NAME" ]; then GIT_NAME="PLACEHOLDER"; fi
if [ -z "$GIT_EMAIL" ]; then GIT_EMAIL="placeholder@example.com"; fi

# Save profile
if [ "$DRY_RUN" = "0" ]; then
    mkdir -p "$CONFIG_DIR"
    echo "{\"profile\":\"$PROFILE\",\"detectedAt\":\"$(date -u +%Y-%m-%dT%H:%M:%S)\"}" > "$CONFIG_DIR/profile.json"
else
    info "[WHATIF] Would save profile: $PROFILE → $CONFIG_DIR/profile.json"
fi

echo "  Profile  : $PROFILE_ICON $PROFILE — $PROFILE_REASON"
echo "  Git      : $GIT_NAME <$GIT_EMAIL> ($IDENTITY_SOURCE)"

if [ "$IDENTITY_SOURCE" = "placeholder" ]; then
    warn "Git identity is placeholder — run setup to configure"
fi

# SSH keys
SSH_COUNT=$(find "$HOME/.ssh" -maxdepth 1 -name 'id_*' ! -name '*.pub' 2>/dev/null | wc -l)
if [ "$SSH_COUNT" -gt 0 ]; then
    ok "SSH keys: $SSH_COUNT found"
else
    warn "SSH keys: none"
fi

# GPG signing check (work/server profiles)
if [ "$PROFILE" = "work" ] || [ "$PROFILE" = "server" ]; then
    GPG_KEY=$(git config --global user.signingkey 2>/dev/null || echo "")
    if [ -n "$GPG_KEY" ]; then
        ok "GPG sign: $GPG_KEY"
    else
        warn "GPG sign: not configured"
        info "Run: git config --global user.signingkey <KEY>"
        info "Run: git config --global commit.gpgsign true"
    fi
fi

echo ""
echo -e "${GREEN}>>> 40 — profile-identity OK${NC}"
echo "  profile: $PROFILE, identity: $IDENTITY_SOURCE"

# ═══════════════════════════════════════════════════════════════
# PHASE 50 — SETUP (home only for minimal viable)
# ═══════════════════════════════════════════════════════════════
header "PHASE 50 — PACKAGE SETUP ($PROFILE)"

if [ "$PROFILE" = "home" ] || [ "$PROFILE" = "lab" ]; then
    if [ "$DRY_RUN" = "1" ]; then
        echo "  [WHATIF] Would install packages and set up environment"
        echo "  [WHATIF] Packages: git, curl, build-essential, nodejs, python3, pip, jq, unzip"
        echo "  [WHATIF] Dirs: ~/dev/projects/, ~/bin/"
        echo "  [WHATIF] Git config: autocrlf=input"
    else
        # Detect package manager
        PKG_MGR=""
        if command -v apt-get &>/dev/null; then
            PKG_MGR="apt"
        elif command -v brew &>/dev/null; then
            PKG_MGR="brew"
        elif command -v dnf &>/dev/null; then
            PKG_MGR="dnf"
        elif command -v pacman &>/dev/null; then
            PKG_MGR="pacman"
        elif command -v apk &>/dev/null; then
            PKG_MGR="apk"
        fi

        if [ -z "$PKG_MGR" ]; then
            warn "No supported package manager found (apt/brew/dnf/pacman/apk)"
            echo "  Install packages manually: git curl build-essential nodejs python3 pip"
        else
            echo "  Package manager: $PKG_MGR"
            
            install_pkg() {
                local pkg=$1
                if command -v "$pkg" &>/dev/null; then
                    ok "$pkg — already installed"
                    return 0
                fi
                echo "  Installing $pkg ..."
                case "$PKG_MGR" in
                    apt)    sudo apt-get install -y "$pkg" 2>&1 | tail -1 ;;
                    brew)   brew install "$pkg" 2>&1 | tail -1 ;;
                    dnf)    sudo dnf install -y "$pkg" 2>&1 | tail -1 ;;
                    pacman) sudo pacman -S --noconfirm "$pkg" 2>&1 | tail -1 ;;
                    apk)    sudo apk add "$pkg" 2>&1 | tail -1 ;;
                esac
                if command -v "$pkg" &>/dev/null; then
                    ok "$pkg — installed"
                else
                    warn "$pkg — install may have failed"
                fi
            }

            # Core packages
            for pkg in git curl jq unzip; do
                install_pkg "$pkg"
            done
            # Build tools (package names vary)
            case "$PKG_MGR" in
                apt)    install_pkg "build-essential" ;;
                dnf)    install_pkg "make" && install_pkg "gcc" && install_pkg "gcc-c++" ;;
                pacman) install_pkg "base-devel" ;;
            esac
            # Node.js
            if command -v node &>/dev/null; then
                ok "node — $(node --version 2>/dev/null || echo '?')"
            else
                case "$PKG_MGR" in
                    apt)    install_pkg "nodejs" && install_pkg "npm" ;;
                    brew)   install_pkg "node" ;;
                    dnf)    install_pkg "nodejs" ;;
                    pacman) install_pkg "nodejs" && install_pkg "npm" ;;
                esac
            fi
            # Python
            if command -v python3 &>/dev/null; then
                ok "python3 — $(python3 --version 2>&1 || echo '?')"
            else
                install_pkg "python3" && install_pkg "python3-pip"
            fi
        fi

        # Directories
        echo ""
        echo "  Setting up directories ..."
        mkdir -p "$HOME/dev/projects"
        mkdir -p "$HOME/bin"
        ok "~/dev/projects/"
        ok "~/bin/"

        # Git config
        if command -v git &>/dev/null; then
            echo ""
            echo "  Git configuration ..."
            git config --global core.autocrlf input 2>/dev/null && ok "git autocrlf = input" || warn "git autocrlf not set"
            if [ -n "$GIT_NAME" ] && [ "$GIT_NAME" != "PLACEHOLDER" ]; then
                git config --global user.name "$GIT_NAME" 2>/dev/null
                git config --global user.email "$GIT_EMAIL" 2>/dev/null
                ok "git identity configured"
            fi
        fi

        # Symlink configs (if repo exists)
        if [ "$HAS_REPO" = "1" ] && [ -f "$REPO_DIR/configs/git/.gitconfig" ]; then
            echo ""
            echo "  Symlinking configs ..."
            if [ ! -f "$HOME/.gitconfig" ] || [ -L "$HOME/.gitconfig" ]; then
                ln -sf "$REPO_DIR/configs/git/.gitconfig" "$HOME/.gitconfig" 2>/dev/null && ok ".gitconfig → repo" || warn ".gitconfig symlink failed"
            else
                warn ".gitconfig exists (not a symlink) — skipped"
            fi
        fi
    fi
elif [ "$PROFILE" = "work" ]; then
    echo "  🏢 Corporate profile — safeMode"
    echo "  Packages must be installed manually or by IT."
    echo "  Run: scripts/50-setup-work.ps1 from Windows host if dual-boot."
    info "Proxy detected — ensure git/npm/pip proxy config is set"
elif [ "$PROFILE" = "server" ]; then
    echo "  🖳 Server profile — safeMode, headless"
    echo "  Install only: git, curl, openssh-server"
    if [ "$DRY_RUN" = "0" ] && command -v apt-get &>/dev/null; then
        sudo apt-get install -y git curl openssh-server 2>&1 | tail -3
        ok "Minimal server packages installed"
    fi
fi

# ═══════════════════════════════════════════════════════════════
# DONE
# ═══════════════════════════════════════════════════════════════
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  ✅  BOOTSTRAP COMPLETE                  ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════╝${NC}"
echo ""
echo "  Profile : $PROFILE_ICON $PROFILE"
echo "  Identity: $GIT_NAME <$GIT_EMAIL>"
echo "  Report  : $REPORT_FILE"
if [ "$HAS_REPO" = "1" ]; then
    echo "  Repo    : $REPO_DIR"
fi
echo ""
echo "  Next steps / Další kroky:"
if [ "$HAS_REPO" = "1" ]; then
    echo "    cd $REPO_DIR"
    echo "    # Review what was installed:"
    echo "    cat $REPORT_FILE"
fi
echo ""

# Raw JSON for AI consumption
echo "# RAW JSON (for AI agents):"
cat "$REPORT_FILE"

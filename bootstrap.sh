#!/usr/bin/env bash
# === bootstrap.sh =============================================
# URL:    https://gist.github.com/doma77git/2f489d9ce5e7e0ff75b17cbe8011bbb5
# ROLE:   Detect environment + point to repo + clone (if git)
#         Detekce prostředí + pointer na repo + clone (pokud git)
# RUN:    curl -fsSL <url> | bash                              (Linux/WSL)
# PARTNER: bootstrap.ps1 — irm <url> | iex                      (Windows)
# PATTERN: curl -fsSL <url>/bootstrap.sh | bash (dotfiles standard)
# ==============================================================
set -euo pipefail

REPO_URL="https://github.com/doma77git/dev-env"                    # REPO — kam ukazuje gist
ENV_DIR="$HOME/.dev-env"                                        # LOCAL — výstupní složka
REPO_DIR="$ENV_DIR/repo"                                        # LOCAL — kam se klonuje

# ═══ 1. DETECT — machine inventory (self‑contained, no git) ═══
#         Inventura stroje — nepotřebuje git, vše je uvnitř
echo ">>> DETECT / DETEKCE"

mkdir -p "$ENV_DIR"                                             # 1a. Output dir

# 1b. Fingerprint — SHA256(hostname|username|domain)
#     Jednoznačný otisk stroje
HOSTNAME=$(hostname)
USERNAME=$(whoami)
DOMAIN="localhost"                                              # Linux nemá doménu jako Windows
FINGERPRINT=$(echo -n "$HOSTNAME|$USERNAME|$DOMAIN" | sha256sum | cut -d' ' -f1)

# 1d. OS — distro, kernel, arch
#     Operační systém
OS_INFO=$(cat /etc/os-release 2>/dev/null | grep PRETTY_NAME | cut -d= -f2 | tr -d '"')
KERNEL=$(uname -r)
ARCH=$(uname -m)

# 1e. Tools — installed tools (Get-Command + --version equivalent)
#     Detekce nástrojů — stejné klíče jako bootstrap.ps1
tools_json() {
    for t in git node python code docker gh curl 7z nvim; do
        if cmd=$(command -v "$t" 2>/dev/null); then
            ver=$( ("$t" --version 2>/dev/null || "$t" -v 2>/dev/null) | head -1 | tr -d '\n' )
            echo "  \"$t\": \"$ver | $cmd\","
        else
            echo "  \"$t\": null,"
        fi
    done
}

# 1f. PATH — count entries
#     Počet položek
PATH_COUNT=$(echo "$PATH" | tr ':' '\n' | grep -c .)

# 1h. Corporate — firemní signály (Linux: minimální)
IN_DOMAIN="false"

# 1i. Status — first run on Linux = always "new" for now
#     První verze Linux detekce — vždy "new" (cache se bude řešit později)
STATUS="new"

# ═══ 2. REPORT — build JSON ══════════════════════════════════
#         Sestavit strukturovaný výstup
REPORT_FILE="$ENV_DIR/report-$(date -u +%Y-%m-%d-%H%M%S).json"

cat > "$REPORT_FILE" << EOF
{
  "meta": {
    "bootstrap": "1.0.0",
    "at": "$(date -u +%Y-%m-%dT%H:%M:%S)",
    "repo": "$REPO_URL",
    "platform": "linux"
  },
  "status": "$STATUS",
  "fingerprint": "$FINGERPRINT",
  "hostname": "$HOSTNAME",
  "username": "$USERNAME",
  "os": {
    "caption": "$OS_INFO",
    "kernel": "$KERNEL",
    "arch": "$ARCH"
  },
  "tools": {
$(tools_json)
  },
  "path": {
    "count": $PATH_COUNT,
    "errors": []
  },
  "corporate": {
    "domainJoined": $IN_DOMAIN
  },
  "changes": []
}
EOF

# ═══ 3. OUTPUT — status to console ═══════════════════════════
#         Výstup pro uživatele
echo ""
echo "  STATUS : $STATUS  (🟢 same / 🟡 tools / 🟠 os / 🔴 new)"
echo "  REPO   : $REPO_URL"
echo "  RPT    : $REPORT_FILE"

# ═══ 4. CLONE — download repo (only if git exists) ═══════════
#         git clone → ~/.dev-env/repo/
if command -v git &>/dev/null; then
    echo ""
    echo ">>> CLONE / KLONUJI REPO"
    if [ -d "$REPO_DIR" ]; then
        echo "  Already exists / Repo existuje — pulling ..."
        git -C "$REPO_DIR" pull || echo "  Pull failed / selhal"
    else
        echo "  git clone $REPO_URL $REPO_DIR"
        git clone "$REPO_URL" "$REPO_DIR" || echo "  Clone failed / selhal"
    fi
    echo "  Repo: $REPO_DIR"
else
    echo ""
    echo ">>> GIT NOT FOUND / GIT NENALEZEN — skipping clone"
    echo "  Install git and run bootstrap again. / Nainstaluj git a spus bootstrap znovu."
fi

# ═══ 5. RAW JSON — for AI agent copy ═════════════════════════
echo ""
cat "$REPORT_FILE"

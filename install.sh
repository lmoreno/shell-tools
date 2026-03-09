#!/usr/bin/env bash
# shell-tools installation script
#
# NOTE: This file must remain at the repository root (not in src/)
# to maintain the curl installation URL:
# curl -fsSL https://raw.githubusercontent.com/lmoreno/shell-tools/main/install.sh | bash
#

set -e

REPO="lmoreno/shell-tools"
INSTALL_DIR="$HOME/.shell-tools"
ZSHRC="$HOME/.zshrc"
BACKUP_DIR="$HOME/.zshrc.backup.$(date +%Y%m%d-%H%M%S)"

echo "=========================================="
echo "  shell-tools installer"
echo "=========================================="
echo ""

# Install prerequisites (zsh and unzip) on Linux if missing
if [[ "$(uname)" == "Linux" ]] && command -v apt-get &>/dev/null; then
    PREREQS=()
    command -v zsh &>/dev/null || PREREQS+=(zsh)
    command -v unzip &>/dev/null || PREREQS+=(unzip)

    if [[ ${#PREREQS[@]} -gt 0 ]]; then
        echo "📦 Installing prerequisites: ${PREREQS[*]}"
        SUDO_CMD=""
        if [[ $EUID -ne 0 ]]; then
            if command -v sudo &>/dev/null && sudo -n true &>/dev/null; then
                SUDO_CMD="sudo"
            else
                echo "❌ Missing: ${PREREQS[*]}"
                echo "   Please install manually: sudo apt-get install ${PREREQS[*]}"
                exit 1
            fi
        fi
        $SUDO_CMD apt-get install -y "${PREREQS[@]}" || {
            echo "❌ Failed to install prerequisites"
            exit 1
        }
        echo "   ✓ Installed ${PREREQS[*]}"
        echo ""
    fi
fi

# Get latest release info from GitHub API
echo "📡 Fetching latest version..."
LATEST_RELEASE_JSON=$(curl -fsSL "https://api.github.com/repos/$REPO/releases/latest")
VERSION=$(echo "$LATEST_RELEASE_JSON" | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')
DOWNLOAD_URL=$(
  echo "$LATEST_RELEASE_JSON" |
  awk '
    /"name": *"shell-tools.zip"/ {
      asset_block = 1;
      next;
    }
    asset_block == 1 {
      if (/"browser_download_url":/) {
        sub(/.*"browser_download_url": "/, "");
        sub(/".*/, "");
        print;
        asset_block = 0;
      }
    }
  '
)

if [[ -z "$VERSION" ]] || [[ -z "$DOWNLOAD_URL" ]]; then
    echo "❌ Failed to fetch release info or custom asset URL"
    echo "Please ensure a 'shell-tools.zip' asset exists in the latest release."
    exit 1
fi

echo "   Latest version: $VERSION"
echo ""

# Backup existing .zshrc
if [[ -f "$ZSHRC" ]]; then
    echo "📦 Backing up ~/.zshrc"
    cp "$ZSHRC" "$BACKUP_DIR"
    echo "   ✓ Backup: $BACKUP_DIR"
fi

# Remove old installation if exists
if [[ -d "$INSTALL_DIR" ]]; then
    echo ""
    echo "📂 Removing old installation"
    rm -rf "$INSTALL_DIR"
fi

# Download and extract release
echo ""
echo "📥 Downloading shell-tools $VERSION"
TEMP_DIR=$(mktemp -d)
TEMP_ZIP="$TEMP_DIR/shell-tools.zip"
curl -fsSL "$DOWNLOAD_URL" -o "$TEMP_ZIP"

echo "📦 Extracting to $INSTALL_DIR"
unzip -q "$TEMP_ZIP" -d "$TEMP_DIR"

# Clean up zip file to avoid moving it
rm "$TEMP_ZIP"

# Create install dir
mkdir -p "$INSTALL_DIR"

# Move contents to install dir (handling normal files and dotfiles)
mv "$TEMP_DIR"/* "$INSTALL_DIR" 2>/dev/null || true
mv "$TEMP_DIR"/.[!.]* "$INSTALL_DIR" 2>/dev/null || true

rm -rf "$TEMP_DIR"

# Record installation timestamp
mkdir -p "$INSTALL_DIR/cache"
date +%s > "$INSTALL_DIR/cache/.installed_at"

echo "   ✓ Installed $VERSION"

# Add to .zshrc if not already present
echo ""
echo "📝 Configuring ~/.zshrc"
if grep -q "source.*shell-tools/plugin.zsh" "$ZSHRC" 2>/dev/null; then
    echo "   ℹ️  Already configured"
else
    cat >> "$ZSHRC" << 'EOF'

# =============================================================================
# SHELL-TOOLS - Personal Zsh Plugin System
# =============================================================================
source ~/.shell-tools/plugin.zsh
EOF
    echo "   ✓ Added source line"
fi

# Add to .bashrc if not already present (for bash-to-zsh auto-switch)
BASHRC="$HOME/.bashrc"
echo ""
echo "📝 Configuring ~/.bashrc"
if grep -q "shell-tools" "$BASHRC" 2>/dev/null; then
    echo "   ℹ️  Already configured"
else
    cat >> "$BASHRC" << 'EOF'

# shell-tools bash initialization (auto-switch to zsh)
[[ -f ~/.shell-tools/lib/bash-init.sh ]] && source ~/.shell-tools/lib/bash-init.sh
EOF
    echo "   ✓ Added source line"
fi

echo ""
echo "=========================================="
echo "✅ Installation complete!"
echo "=========================================="
echo ""
echo "Version installed: $VERSION"
echo ""
echo "Next steps:"
echo "  1. Review ~/.zshrc for duplicate aliases"
echo "  2. Restart shell: exec zsh"
echo "  3. Verify: st-version"
echo ""

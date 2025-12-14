#!/usr/bin/env bash
# shell-tools installation script

set -e

INSTALL_DIR="$HOME/.shell-tools"
ZSHRC="$HOME/.zshrc"
BACKUP_DIR="$HOME/.zshrc.backup.$(date +%Y%m%d-%H%M%S)"

echo "=========================================="
echo "  shell-tools installer"
echo "=========================================="
echo ""

# Backup existing .zshrc
if [[ -f "$ZSHRC" ]]; then
    echo "📦 Backing up ~/.zshrc to $BACKUP_DIR"
    cp "$ZSHRC" "$BACKUP_DIR"
    echo "   ✓ Backup created"
else
    echo "⚠️  No existing ~/.zshrc found"
fi

# Clone or update repository
if [[ -d "$INSTALL_DIR" ]]; then
    echo ""
    echo "📂 shell-tools exists at $INSTALL_DIR"
    read -p "   Update? (y/n): " update
    if [[ "$update" == "y" ]]; then
        cd "$INSTALL_DIR" && git pull
        echo "   ✓ Updated"
    fi
else
    echo ""
    echo "📥 Cloning to $INSTALL_DIR"
    git clone git@github.com:lmoreno/shell-tools.git "$INSTALL_DIR"
    echo "   ✓ Cloned"
fi

# Add shell-tools source statement
echo ""
echo "📝 Adding shell-tools to ~/.zshrc"

if grep -q "source.*shell-tools/plugin.zsh" "$ZSHRC" 2>/dev/null; then
    echo "   ℹ️  Already sourced"
else
    cat >> "$ZSHRC" << 'EOF'

# =============================================================================
# SHELL-TOOLS - Personal Zsh Plugin System
# =============================================================================
source ~/.shell-tools/plugin.zsh
EOF
    echo "   ✓ Added source line"
fi

# Summary
echo ""
echo "=========================================="
echo "✅ Installation complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "  1. Review your ~/.zshrc and remove any duplicate aliases/functions"
echo "     (shell-tools provides: git/docker/npm aliases, eza/bat/rg, etc.)"
echo "  2. Restart shell: exec zsh"
echo "  3. Verify: st-version"
echo ""
echo "Backup location: $BACKUP_DIR"
echo ""
echo "Customization:"
echo "  • Edit aliases: vim ~/.shell-tools/modules/aliases.zsh"
echo "  • Edit functions: vim ~/.shell-tools/modules/functions.zsh"
echo "  • After changes: st-reload"
echo ""
echo "Tip: Keep project-specific aliases in ~/.zshrc after the source line"
echo ""

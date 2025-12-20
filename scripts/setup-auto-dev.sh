#!/bin/bash

ZSHRC="$HOME/.zshrc"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "Setting up automatic dev mode for shell-tools..."
echo ""
echo "This will add a zsh hook to automatically activate dev mode"
echo "when you cd into the project directory: $PROJECT_DIR"
echo ""

# Check if already configured
if grep -q "shell-tools auto dev mode" "$ZSHRC" 2>/dev/null; then
    echo "⚠️  Auto dev mode is already configured in $ZSHRC"
    echo ""
    echo "To remove it, edit $ZSHRC and delete the section marked:"
    echo "  # shell-tools auto dev mode"
    exit 0
fi

# Create the hook function (use non-quoted heredoc to expand PROJECT_DIR)
cat >> "$ZSHRC" << EOF

# shell-tools auto dev mode
# Automatically activate dev mode when entering the project directory
_shell_tools_auto_dev() {
    local project_dir="$PROJECT_DIR"

    # Check if we're in the project directory (or subdirectory)
    if [[ "\$PWD" == "\$project_dir"* ]] && [[ -f "\$project_dir/src/.dev" ]]; then
        # Check if we're not already in dev mode
        if [[ "\$SHELL_TOOLS_ROOT" != "\$project_dir/src" ]]; then
            source "\$project_dir/src/plugin.zsh"
        fi
    fi
}

# Register the hook to run on directory change
autoload -U add-zsh-hook
add-zsh-hook chpwd _shell_tools_auto_dev
EOF

echo "✅ Auto dev mode configured!"
echo ""
echo "To activate the changes, either:"
echo "  1. Restart your shell, or"
echo "  2. Run: source ~/.zshrc"
echo ""
echo "Now when you cd into $PROJECT_DIR,"
echo "dev mode will automatically activate!"

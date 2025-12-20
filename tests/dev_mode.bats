#!/usr/bin/env bats

load 'test_helper'

setup() {
    common_setup
}

@test "Dev Mode: detects .dev marker file and activates dev mode" {
    # Copy src files including .dev marker (including hidden files)
    mkdir -p "$HOME/dev-project"
    cp -r "$SRC_ROOT/lib" "$HOME/dev-project/"
    cp -r "$SRC_ROOT/modules" "$HOME/dev-project/"
    cp -r "$SRC_ROOT/tools" "$HOME/dev-project/"
    cp -r "$SRC_ROOT/cache" "$HOME/dev-project/" 2>/dev/null || true
    cp "$SRC_ROOT/plugin.zsh" "$HOME/dev-project/"
    cp "$SRC_ROOT/VERSION" "$HOME/dev-project/"
    cp "$SRC_ROOT/.dev" "$HOME/dev-project/"  # Explicitly copy .dev marker

    # Verify .dev file exists
    assert [ -f "$HOME/dev-project/.dev" ]

    # Source plugin and check for dev mode activation
    # Run from $HOME to avoid auto-detection issues
    run zsh -c "cd $HOME && source $HOME/dev-project/plugin.zsh 2>&1"
    assert_output --partial "🔧 Development mode active"

    # Verify SHELL_TOOLS_DEV is set
    run zsh -c "cd $HOME && source $HOME/dev-project/plugin.zsh >/dev/null 2>&1 && echo \$SHELL_TOOLS_DEV"
    assert_output "1"
}

@test "Dev Mode: normal mode without .dev marker" {
    # Install to sandbox WITHOUT .dev file
    mkdir -p "$HOME/.shell-tools"
    cp -r "$SRC_ROOT/lib" "$HOME/.shell-tools/"
    cp -r "$SRC_ROOT/modules" "$HOME/.shell-tools/"
    cp -r "$SRC_ROOT/tools" "$HOME/.shell-tools/"
    cp "$SRC_ROOT/plugin.zsh" "$HOME/.shell-tools/"
    cp "$SRC_ROOT/VERSION" "$HOME/.shell-tools/"
    # Explicitly NOT copying .dev file

    # Verify .dev file does NOT exist
    assert [ ! -f "$HOME/.shell-tools/.dev" ]

    # Source plugin - should NOT show dev mode message
    # Run from $HOME to avoid auto-detection finding project's src/.dev
    run zsh -c "cd $HOME && source $HOME/.shell-tools/plugin.zsh 2>&1"
    refute_output --partial "🔧 Development mode active"

    # Verify SHELL_TOOLS_DEV is NOT set
    run zsh -c "cd $HOME && source $HOME/.shell-tools/plugin.zsh >/dev/null 2>&1 && echo \"DEV:\$SHELL_TOOLS_DEV\""
    assert_output "DEV:"
}

@test "Dev Mode: logs show [DEV] prefix in dev mode" {
    # Copy src files including .dev marker
    mkdir -p "$HOME/dev-project"
    cp -r "$SRC_ROOT/lib" "$HOME/dev-project/"
    cp -r "$SRC_ROOT/modules" "$HOME/dev-project/"
    cp -r "$SRC_ROOT/tools" "$HOME/dev-project/"
    cp "$SRC_ROOT/plugin.zsh" "$HOME/dev-project/"
    cp "$SRC_ROOT/VERSION" "$HOME/dev-project/"
    cp "$SRC_ROOT/.dev" "$HOME/dev-project/"  # Explicitly copy .dev marker

    # Force cache regeneration to see logs
    # Run from $HOME to avoid auto-detection issues
    run zsh -c "cd $HOME && source $HOME/dev-project/plugin.zsh 2>&1"

    # Check for [DEV] prefix in logs (after initial activation message)
    assert_output --partial "[DEV]"
}

@test "Dev Mode: logs do NOT show [DEV] prefix in normal mode" {
    # Install without .dev
    mkdir -p "$HOME/.shell-tools"
    cp -r "$SRC_ROOT/lib" "$HOME/.shell-tools/"
    cp -r "$SRC_ROOT/modules" "$HOME/.shell-tools/"
    cp -r "$SRC_ROOT/tools" "$HOME/.shell-tools/"
    cp "$SRC_ROOT/plugin.zsh" "$HOME/.shell-tools/"
    cp "$SRC_ROOT/VERSION" "$HOME/.shell-tools/"

    # Source and check logs
    # Run from $HOME to avoid auto-detection finding project's src/.dev
    run zsh -c "cd $HOME && source $HOME/.shell-tools/plugin.zsh 2>&1"

    # Should NOT contain [DEV] prefix
    refute_output --partial "[DEV]"
}

@test "Dev Mode: uses separate cache directory" {
    # Set up dev environment
    mkdir -p "$HOME/dev-project"
    cp -r "$SRC_ROOT/lib" "$HOME/dev-project/"
    cp -r "$SRC_ROOT/modules" "$HOME/dev-project/"
    cp -r "$SRC_ROOT/tools" "$HOME/dev-project/"
    cp "$SRC_ROOT/plugin.zsh" "$HOME/dev-project/"
    cp "$SRC_ROOT/VERSION" "$HOME/dev-project/"
    cp "$SRC_ROOT/.dev" "$HOME/dev-project/"

    # Source plugin to generate cache
    # Run from $HOME to avoid auto-detection issues
    run zsh -c "cd $HOME && source $HOME/dev-project/plugin.zsh >/dev/null 2>&1"

    # Verify dev cache exists
    assert [ -d "$HOME/dev-project/cache" ]
    assert [ -f "$HOME/dev-project/cache/init.zsh" ]
}

@test "Dev Mode: SHELL_TOOLS_ROOT points to correct directory" {
    # Dev mode
    mkdir -p "$HOME/dev-project"
    cp -r "$SRC_ROOT/lib" "$HOME/dev-project/"
    cp -r "$SRC_ROOT/modules" "$HOME/dev-project/"
    cp -r "$SRC_ROOT/tools" "$HOME/dev-project/"
    cp "$SRC_ROOT/plugin.zsh" "$HOME/dev-project/"
    cp "$SRC_ROOT/VERSION" "$HOME/dev-project/"
    cp "$SRC_ROOT/.dev" "$HOME/dev-project/"

    # Run from $HOME to avoid auto-detection issues
    run zsh -c "cd $HOME && source $HOME/dev-project/plugin.zsh >/dev/null 2>&1 && echo \$SHELL_TOOLS_ROOT"
    # Use pattern matching to handle /var vs /private/var on macOS
    assert_output --partial "/dev-project"

    # Normal mode
    mkdir -p "$HOME/.shell-tools"
    cp -r "$SRC_ROOT/lib" "$HOME/.shell-tools/"
    cp -r "$SRC_ROOT/modules" "$HOME/.shell-tools/"
    cp -r "$SRC_ROOT/tools" "$HOME/.shell-tools/"
    cp "$SRC_ROOT/plugin.zsh" "$HOME/.shell-tools/"
    cp "$SRC_ROOT/VERSION" "$HOME/.shell-tools/"

    # Run from $HOME to avoid auto-detection finding project's src/.dev
    run zsh -c "cd $HOME && source $HOME/.shell-tools/plugin.zsh >/dev/null 2>&1 && echo \$SHELL_TOOLS_ROOT"
    assert_output --partial "/.shell-tools"
}

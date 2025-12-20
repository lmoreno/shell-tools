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

@test "Dev Mode: chpwd hook registered in normal mode" {
    # Install normal version WITHOUT .dev file
    mkdir -p "$HOME/.shell-tools"
    cp -r "$SRC_ROOT/lib" "$HOME/.shell-tools/"
    cp -r "$SRC_ROOT/modules" "$HOME/.shell-tools/"
    cp -r "$SRC_ROOT/tools" "$HOME/.shell-tools/"
    cp "$SRC_ROOT/plugin.zsh" "$HOME/.shell-tools/"
    cp "$SRC_ROOT/VERSION" "$HOME/.shell-tools/"
    # Explicitly NOT copying .dev file

    # Source plugin and verify _shell_tools_detect_dev function exists
    run zsh -c "cd $HOME && source $HOME/.shell-tools/plugin.zsh >/dev/null 2>&1 && type _shell_tools_detect_dev"
    assert_success
    assert_output --partial "function"
}

@test "Dev Mode: auto-switches when entering dev project directory" {
    # Install normal version at ~/.shell-tools (WITHOUT .dev)
    mkdir -p "$HOME/.shell-tools"
    cp -r "$SRC_ROOT/lib" "$HOME/.shell-tools/"
    cp -r "$SRC_ROOT/modules" "$HOME/.shell-tools/"
    cp -r "$SRC_ROOT/tools" "$HOME/.shell-tools/"
    cp "$SRC_ROOT/plugin.zsh" "$HOME/.shell-tools/"
    cp "$SRC_ROOT/VERSION" "$HOME/.shell-tools/"

    # Create a dev project at ~/projects/my-dev-project/src/
    mkdir -p "$HOME/projects/my-dev-project/src"
    cp -r "$SRC_ROOT/lib" "$HOME/projects/my-dev-project/src/"
    cp -r "$SRC_ROOT/modules" "$HOME/projects/my-dev-project/src/"
    cp -r "$SRC_ROOT/tools" "$HOME/projects/my-dev-project/src/"
    cp "$SRC_ROOT/plugin.zsh" "$HOME/projects/my-dev-project/src/"
    cp "$SRC_ROOT/VERSION" "$HOME/projects/my-dev-project/src/"
    cp "$SRC_ROOT/.dev" "$HOME/projects/my-dev-project/src/"  # Include .dev marker

    # Source normal plugin from $HOME, then cd into dev project and call chpwd hook
    # The hook should detect src/.dev and switch to dev mode
    run zsh -c "
        cd $HOME
        source $HOME/.shell-tools/plugin.zsh >/dev/null 2>&1
        # Verify we're in normal mode initially
        [[ -z \$SHELL_TOOLS_DEV ]] || exit 1
        # Simulate cd into dev project
        cd $HOME/projects/my-dev-project
        # Call the chpwd hook directly (since we can't trigger real chpwd in subshell)
        # Note: This sources the dev plugin which outputs messages - we just check the result
        _shell_tools_detect_dev
        # Check if dev mode is now active
        echo \"DEV_MODE_RESULT:\$SHELL_TOOLS_DEV\"
    "
    assert_success
    # Check dev mode message was shown and SHELL_TOOLS_DEV=1
    assert_output --partial "Development mode active"
    assert_output --partial "DEV_MODE_RESULT:1"
}

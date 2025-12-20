#!/usr/bin/env bats

load 'test_helper'

setup() {
    common_setup

    # Install shell-tools to simulate installed version
    mkdir -p "$HOME/.shell-tools"
    cp -r "$SRC_ROOT/lib" "$HOME/.shell-tools/"
    cp -r "$SRC_ROOT/modules" "$HOME/.shell-tools/"
    cp -r "$SRC_ROOT/tools" "$HOME/.shell-tools/"
    cp "$SRC_ROOT/plugin.zsh" "$HOME/.shell-tools/"
    cp "$SRC_ROOT/VERSION" "$HOME/.shell-tools/"
    mkdir -p "$HOME/.shell-tools/cache"

    # Also create a dev version (simulating src/ directory)
    mkdir -p "$HOME/dev-project/src"
    cp -r "$SRC_ROOT/lib" "$HOME/dev-project/src/"
    cp -r "$SRC_ROOT/modules" "$HOME/dev-project/src/"
    cp -r "$SRC_ROOT/tools" "$HOME/dev-project/src/"
    cp "$SRC_ROOT/plugin.zsh" "$HOME/dev-project/src/"
    cp "$SRC_ROOT/VERSION" "$HOME/dev-project/src/"
    touch "$HOME/dev-project/src/.dev"
    mkdir -p "$HOME/dev-project/src/cache"
}

@test "Isolation: git include is replaced when switching from installed to dev" {
    # First, source installed version to add its git include
    run zsh -c "cd $HOME && source $HOME/.shell-tools/plugin.zsh"
    assert_success

    # Verify installed git include was added
    run git config --global --get-all include.path
    assert_output --partial ".shell-tools/cache/git-aliases"

    # Now source dev version - it should replace the installed include
    run zsh -c "cd $HOME && source $HOME/dev-project/src/plugin.zsh"
    assert_success

    # Verify only dev git include exists (installed should be removed)
    run git config --global --get-all include.path
    assert_output --partial "dev-project/src/cache/git-aliases"
    refute_output --partial ".shell-tools/cache/git-aliases"
}

@test "Isolation: git include is replaced when switching from dev to installed" {
    # First, source dev version to add its git include
    run zsh -c "cd $HOME && source $HOME/dev-project/src/plugin.zsh"
    assert_success

    # Verify dev git include was added
    run git config --global --get-all include.path
    assert_output --partial "dev-project/src/cache/git-aliases"

    # Now source installed version - it should replace the dev include
    run zsh -c "cd $HOME && source $HOME/.shell-tools/plugin.zsh"
    assert_success

    # Verify only installed git include exists (dev should be removed)
    run git config --global --get-all include.path
    assert_output --partial ".shell-tools/cache/git-aliases"
    refute_output --partial "dev-project/src/cache/git-aliases"
}

@test "Isolation: only one shell-tools git include exists after multiple reloads" {
    # Source installed version multiple times
    run zsh -c "cd $HOME && source $HOME/.shell-tools/plugin.zsh && st-reload && st-reload"
    assert_success

    # Count shell-tools git includes
    local count
    count=$(git config --global --get-all include.path | grep -c "shell-tools.*git-aliases" || echo "0")

    # Should only have one include
    assert [ "$count" -eq 1 ]
}

@test "Isolation: dev and installed have separate SHELL_TOOLS_ROOT" {
    # Check installed SHELL_TOOLS_ROOT
    run zsh -c "cd $HOME && source $HOME/.shell-tools/plugin.zsh && echo \$SHELL_TOOLS_ROOT"
    assert_success
    assert_output --partial ".shell-tools"

    # Check dev SHELL_TOOLS_ROOT
    run zsh -c "cd $HOME && source $HOME/dev-project/src/plugin.zsh && echo \$SHELL_TOOLS_ROOT"
    assert_success
    assert_output --partial "dev-project/src"
}

@test "Isolation: dev and installed have separate cache directories" {
    # Source installed and check cache path
    run zsh -c "cd $HOME && source $HOME/.shell-tools/plugin.zsh && ls -d \$SHELL_TOOLS_ROOT/cache"
    assert_success
    assert_output --partial ".shell-tools/cache"

    # Source dev and check cache path
    run zsh -c "cd $HOME && source $HOME/dev-project/src/plugin.zsh && ls -d \$SHELL_TOOLS_ROOT/cache"
    assert_success
    assert_output --partial "dev-project/src/cache"
}

@test "Isolation: SHELL_TOOLS_DEV is set only in dev mode" {
    # Check installed mode - should not have SHELL_TOOLS_DEV
    run zsh -c "cd $HOME && source $HOME/.shell-tools/plugin.zsh >/dev/null 2>&1 && echo \"DEV:\$SHELL_TOOLS_DEV\""
    assert_success
    assert_output "DEV:"

    # Check dev mode - should have SHELL_TOOLS_DEV=1
    run zsh -c "cd $HOME && source $HOME/dev-project/src/plugin.zsh >/dev/null 2>&1 && echo \"DEV:\$SHELL_TOOLS_DEV\""
    assert_success
    assert_output "DEV:1"
}

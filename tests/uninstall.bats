#!/usr/bin/env bats

load 'test_helper'

setup() {
    common_setup

    # Mock Oh-My-Zsh to prevent bootstrap from overwriting .zshrc
    mkdir -p "$HOME/.oh-my-zsh"

    # Install shell-tools
    mkdir -p "$HOME/.shell-tools"
    cp -r "$SRC_ROOT/lib" "$HOME/.shell-tools/"
    cp -r "$SRC_ROOT/modules" "$HOME/.shell-tools/"
    cp -r "$SRC_ROOT/tools" "$HOME/.shell-tools/"
    cp "$SRC_ROOT/plugin.zsh" "$HOME/.shell-tools/"
    cp "$SRC_ROOT/VERSION" "$HOME/.shell-tools/"
    mkdir -p "$HOME/.shell-tools/cache"

    # Create a .zshrc with source line
    echo "# User config" > "$HOME/.zshrc"
    echo "source $HOME/.shell-tools/plugin.zsh" >> "$HOME/.zshrc"
    echo "# More config" >> "$HOME/.zshrc"
}

@test "Uninstall: st-uninstall command exists" {
    run zsh -c "cd $HOME && source $HOME/.shell-tools/plugin.zsh >/dev/null 2>&1 && type st-uninstall"
    assert_success
}

@test "Uninstall: fails if shell-tools not installed" {
    rm -rf "$HOME/.shell-tools"

    # Use dev version to test
    run zsh -c "source $SRC_ROOT/plugin.zsh >/dev/null 2>&1 && st-uninstall"
    assert_failure
    assert_output --partial "not installed"
}

@test "Uninstall: shows what will be removed" {
    run zsh -c "cd $HOME && source $HOME/.shell-tools/plugin.zsh >/dev/null 2>&1 && st-uninstall <<< '3'"
    assert_success
    assert_output --partial "~/.shell-tools/"
    assert_output --partial "Source line from ~/.zshrc"
}

@test "Uninstall: can be cancelled" {
    run zsh -c "cd $HOME && source $HOME/.shell-tools/plugin.zsh >/dev/null 2>&1 && st-uninstall <<< 'n'"
    assert_success
    assert_output --partial "cancelled"

    # Verify nothing was removed
    assert [ -d "$HOME/.shell-tools" ]
    assert [ -f "$HOME/.zshrc" ]
    grep -q "shell-tools" "$HOME/.zshrc"
}

@test "Uninstall: removes installation directory" {
    run zsh -c "cd $HOME && source $HOME/.shell-tools/plugin.zsh >/dev/null 2>&1 && st-uninstall <<< 'y'"
    assert_success

    # Verify directory was removed
    assert [ ! -d "$HOME/.shell-tools" ]
}

@test "Uninstall: removes source line from .zshrc" {
    run zsh -c "cd $HOME && source $HOME/.shell-tools/plugin.zsh >/dev/null 2>&1 && st-uninstall <<< 'y'"
    assert_success

    # Verify source line was removed but other content remains
    assert [ -f "$HOME/.zshrc" ]
    run grep "shell-tools" "$HOME/.zshrc"
    assert_failure

    # Other config should remain
    run grep "User config" "$HOME/.zshrc"
    assert_success
}

@test "Uninstall: removes git include from gitconfig" {
    # First ensure git include exists
    run zsh -c "cd $HOME && source $HOME/.shell-tools/plugin.zsh"
    assert_success

    # Verify git include was added
    run git config --global --get-all include.path
    assert_output --partial "git-aliases"

    # Now uninstall
    run zsh -c "cd $HOME && source $HOME/.shell-tools/plugin.zsh >/dev/null 2>&1 && st-uninstall <<< 'y'"
    assert_success

    # Verify git include was removed
    run git config --global --get-all include.path
    refute_output --partial "git-aliases"
}

@test "Uninstall: detects user customizations" {
    # Create local.zsh
    echo "# My custom aliases" > "$HOME/.shell-tools/modules/local.zsh"

    run zsh -c "cd $HOME && source $HOME/.shell-tools/plugin.zsh >/dev/null 2>&1 && st-uninstall <<< '3'"
    assert_success
    assert_output --partial "Found user customizations"
    assert_output --partial "local.zsh"
}

@test "Uninstall: can save customizations before removing" {
    # Create local.zsh
    echo "# My custom aliases" > "$HOME/.shell-tools/modules/local.zsh"

    run zsh -c "cd $HOME && source $HOME/.shell-tools/plugin.zsh >/dev/null 2>&1 && st-uninstall <<< '1'"
    assert_success
    assert_output --partial "Saved customizations"

    # Verify backup was created
    assert [ -f "$HOME/shell-tools-backup/local.zsh" ]
    assert [ ! -d "$HOME/.shell-tools" ]
}

@test "Uninstall: can remove without saving customizations" {
    # Create local.zsh
    echo "# My custom aliases" > "$HOME/.shell-tools/modules/local.zsh"

    run zsh -c "cd $HOME && source $HOME/.shell-tools/plugin.zsh >/dev/null 2>&1 && st-uninstall <<< '2'"
    assert_success

    # Verify no backup was created
    assert [ ! -f "$HOME/shell-tools-backup/local.zsh" ]
    assert [ ! -d "$HOME/.shell-tools" ]
}

@test "Uninstall: offers Oh-My-Zsh removal if marker exists" {
    # Create Oh-My-Zsh marker
    touch "$HOME/.shell-tools/.omz-installed-by-shell-tools"
    mkdir -p "$HOME/.oh-my-zsh"

    # Answer 'y' to main prompt and 'n' to Oh-My-Zsh removal
    run zsh -c "cd $HOME && source $HOME/.shell-tools/plugin.zsh >/dev/null 2>&1 && st-uninstall" <<< $'y\nn'
    assert_success
    assert_output --partial "Oh-My-Zsh was installed by shell-tools"
    assert_output --partial "Keeping Oh-My-Zsh"

    # Oh-My-Zsh should still exist
    assert [ -d "$HOME/.oh-my-zsh" ]
}

@test "Uninstall: can remove Oh-My-Zsh when requested" {
    # Create Oh-My-Zsh marker
    touch "$HOME/.shell-tools/.omz-installed-by-shell-tools"
    mkdir -p "$HOME/.oh-my-zsh"

    # Answer 'y' to both prompts
    run zsh -c "cd $HOME && source $HOME/.shell-tools/plugin.zsh >/dev/null 2>&1 && st-uninstall" <<< $'y\ny'
    assert_success
    assert_output --partial "Removed Oh-My-Zsh"

    # Oh-My-Zsh should be removed
    assert [ ! -d "$HOME/.oh-my-zsh" ]
}

@test "Uninstall: works from dev mode" {
    run zsh -c "source $SRC_ROOT/plugin.zsh >/dev/null 2>&1 && st-uninstall <<< 'y'"
    assert_success
    assert_output --partial "Running st-uninstall from development mode"
    assert_output --partial "Uninstall complete"

    # Verify installed version was removed
    assert [ ! -d "$HOME/.shell-tools" ]
}

@test "Uninstall: leaves shell functional after removal" {
    run zsh -c "cd $HOME && source $HOME/.shell-tools/plugin.zsh >/dev/null 2>&1 && st-uninstall <<< 'y' && echo 'Shell still works'"
    assert_success
    assert_output --partial "Shell still works"
}

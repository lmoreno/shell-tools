#!/usr/bin/env bats

load 'test_helper'

setup() {
    common_setup

    # Install shell-tools
    mkdir -p "$HOME/.shell-tools"
    cp -r "$SRC_ROOT/lib" "$HOME/.shell-tools/"
    cp -r "$SRC_ROOT/modules" "$HOME/.shell-tools/"
    cp -r "$SRC_ROOT/tools" "$HOME/.shell-tools/"
    cp "$SRC_ROOT/plugin.zsh" "$HOME/.shell-tools/"
    cp "$SRC_ROOT/VERSION" "$HOME/.shell-tools/"

    mkdir -p "$HOME/.shell-tools/cache"
}

@test "Info: st-info command exists" {
    run zsh -c "source $HOME/.shell-tools/plugin.zsh && type st-info"
    assert_success
}

@test "Info: shows mode as Installed in normal mode" {
    run zsh -c "cd $HOME && source $HOME/.shell-tools/plugin.zsh && st-info"
    assert_success
    assert_output --partial "Mode"
    assert_output --partial "Installed"
}

@test "Info: shows mode as Development in dev mode" {
    run zsh -c "source $SRC_ROOT/plugin.zsh && st-info"
    assert_success
    assert_output --partial "Mode"
    assert_output --partial "Development"
    assert_output --partial "[DEV]"
}

@test "Info: shows current version" {
    local version
    version=$(cat "$SRC_ROOT/VERSION" | tr -d '[:space:]')

    run zsh -c "cd $HOME && source $HOME/.shell-tools/plugin.zsh && st-info"
    assert_success
    assert_output --partial "Version"
    assert_output --partial "$version"
}

@test "Info: shows paths section" {
    run zsh -c "cd $HOME && source $HOME/.shell-tools/plugin.zsh && st-info"
    assert_success
    assert_output --partial "Paths"
    assert_output --partial "Root"
    assert_output --partial "Cache"
    assert_output --partial "Modules"
}

@test "Info: shows configuration section" {
    run zsh -c "cd $HOME && source $HOME/.shell-tools/plugin.zsh && st-info"
    assert_success
    assert_output --partial "Configuration"
    assert_output --partial "Update Check"
    assert_output --partial "Repository"
}

@test "Info: shows modules section with existing modules" {
    run zsh -c "cd $HOME && source $HOME/.shell-tools/plugin.zsh && st-info"
    assert_success
    assert_output --partial "Modules"
    assert_output --partial "aliases.zsh"
    assert_output --partial "functions.zsh"
}

@test "Info: shows missing local.zsh module" {
    # local.zsh doesn't exist by default
    run zsh -c "cd $HOME && source $HOME/.shell-tools/plugin.zsh && st-info"
    assert_success
    assert_output --partial "local.zsh"
}

@test "Info: shows cache section" {
    run zsh -c "cd $HOME && source $HOME/.shell-tools/plugin.zsh && st-info"
    assert_success
    assert_output --partial "Cache"
    assert_output --partial "Generated"
}

@test "Info: shows git integration section" {
    run zsh -c "cd $HOME && source $HOME/.shell-tools/plugin.zsh && st-info"
    assert_success
    assert_output --partial "Git Integration"
}

@test "Info: latest version check shows result from mock" {
    run zsh -c "cd $HOME && source $HOME/.shell-tools/plugin.zsh && st-info"
    assert_success
    # Mock curl returns current version, so should show "up to date"
    assert_output --partial "up to date"
}

@test "Info: gracefully handles missing VERSION file" {
    rm -f "$HOME/.shell-tools/VERSION"

    run zsh -c "cd $HOME && source $HOME/.shell-tools/plugin.zsh && st-info"
    assert_success
    assert_output --partial "Version"
    assert_output --partial "unknown"
}

@test "Info: respects custom SHELL_TOOLS_UPDATE_CHECK setting" {
    run zsh -c "cd $HOME && export SHELL_TOOLS_UPDATE_CHECK=weekly && source $HOME/.shell-tools/plugin.zsh && st-info"
    assert_success
    assert_output --partial "Update Check"
    assert_output --partial "weekly"
}

@test "Info: respects custom SHELL_TOOLS_REPO setting" {
    run zsh -c "cd $HOME && export SHELL_TOOLS_REPO=custom/repo && source $HOME/.shell-tools/plugin.zsh && st-info"
    assert_success
    assert_output --partial "Repository"
    assert_output --partial "custom/repo"
}

@test "Info: shows health status" {
    run zsh -c "cd $HOME && source $HOME/.shell-tools/plugin.zsh && st-info"
    assert_success
    assert_output --partial "Status"
}

@test "Info: shows timestamps when files exist" {
    # Create timestamp files
    echo "1703123456" > "$HOME/.shell-tools/cache/.installed_at"
    echo "1703123789" > "$HOME/.shell-tools/cache/.last_updated"
    echo "1703124000" > "$HOME/.shell-tools/cache/.last_update_check"

    run zsh -c "cd $HOME && source $HOME/.shell-tools/plugin.zsh && st-info"
    assert_success
    assert_output --partial "Install Date"
    assert_output --partial "Last Update"
    assert_output --partial "Last Check"
}

@test "Info: hides timestamps when files missing" {
    # Ensure no timestamp files exist
    rm -f "$HOME/.shell-tools/cache/.installed_at"
    rm -f "$HOME/.shell-tools/cache/.last_updated"
    rm -f "$HOME/.shell-tools/cache/.last_update_check"

    # Disable update check to prevent .last_update_check from being created during plugin load
    run zsh -c "cd $HOME && export SHELL_TOOLS_UPDATE_CHECK=never && source $HOME/.shell-tools/plugin.zsh && st-info"
    assert_success
    refute_output --partial "Install Date"
    refute_output --partial "Last Update"
    refute_output --partial "Last Check"
}

@test "Info: shows shell-tools header" {
    run zsh -c "cd $HOME && source $HOME/.shell-tools/plugin.zsh && st-info"
    assert_success
    assert_output --partial "shell-tools"
}

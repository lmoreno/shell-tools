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
}

@test "Minimal mode: SHELL_TOOLS_MINIMAL=1 activates minimal mode" {
    # Minimal mode message only shows in interactive shells, so check st-version output instead
    run zsh -c "cd $HOME && SHELL_TOOLS_MINIMAL=1 source $HOME/.shell-tools/plugin.zsh && st-version"
    assert_success
    assert_output --partial "(minimal)"
}

@test "Minimal mode: generates init-minimal.zsh cache" {
    run zsh -c "cd $HOME && SHELL_TOOLS_MINIMAL=1 source $HOME/.shell-tools/plugin.zsh"
    assert_success

    # Check minimal cache was created
    [[ -f "$HOME/.shell-tools/cache/init-minimal.zsh" ]]
    [[ -f "$HOME/.shell-tools/cache/.version-minimal" ]]
}

@test "Minimal mode: does NOT generate full init.zsh cache" {
    run zsh -c "cd $HOME && SHELL_TOOLS_MINIMAL=1 source $HOME/.shell-tools/plugin.zsh"
    assert_success

    # Full cache should NOT exist
    [[ ! -f "$HOME/.shell-tools/cache/init.zsh" ]]
}

@test "Minimal mode: aliases are available" {
    run zsh -c "cd $HOME && SHELL_TOOLS_MINIMAL=1 source $HOME/.shell-tools/plugin.zsh && alias ll"
    assert_success
}

@test "Minimal mode: functions are available" {
    run zsh -c "cd $HOME && SHELL_TOOLS_MINIMAL=1 source $HOME/.shell-tools/plugin.zsh && type take"
    assert_success
    assert_output --partial "function"
}

@test "Minimal mode: st-version shows (minimal) suffix" {
    run zsh -c "cd $HOME && SHELL_TOOLS_MINIMAL=1 source $HOME/.shell-tools/plugin.zsh && st-version"
    assert_success
    assert_output --partial "(minimal)"
}

@test "Minimal mode: st-reload works" {
    run zsh -c "cd $HOME && SHELL_TOOLS_MINIMAL=1 source $HOME/.shell-tools/plugin.zsh && st-reload"
    assert_success
    assert_output --partial "Reloaded"
}

@test "Minimal mode: st-info shows [MINIMAL] header" {
    run zsh -c "cd $HOME && SHELL_TOOLS_MINIMAL=1 source $HOME/.shell-tools/plugin.zsh && st-info"
    assert_success
    assert_output --partial "[MINIMAL]"
    assert_output --partial "aliases.zsh"
    assert_output --partial "functions.zsh"
}

@test "Minimal mode: st-update command exists" {
    run zsh -c "cd $HOME && SHELL_TOOLS_MINIMAL=1 source $HOME/.shell-tools/plugin.zsh && type st-update"
    assert_success
    assert_output --partial "function"
}

@test "Minimal mode: st-uninstall command exists" {
    run zsh -c "cd $HOME && SHELL_TOOLS_MINIMAL=1 source $HOME/.shell-tools/plugin.zsh && type st-uninstall"
    assert_success
    assert_output --partial "function"
}

@test "Minimal mode: does NOT bootstrap Oh-My-Zsh" {
    run zsh -c "cd $HOME && SHELL_TOOLS_MINIMAL=1 source $HOME/.shell-tools/plugin.zsh"
    assert_success

    # Oh-My-Zsh should NOT be installed
    [[ ! -d "$HOME/.oh-my-zsh" ]]
}

@test "Minimal mode: does NOT modify gitconfig" {
    run zsh -c "cd $HOME && SHELL_TOOLS_MINIMAL=1 source $HOME/.shell-tools/plugin.zsh"
    assert_success

    # gitconfig should NOT have shell-tools include
    if [[ -f "$HOME/.gitconfig" ]]; then
        run grep "git-aliases" "$HOME/.gitconfig"
        assert_failure
    fi
}

@test "Minimal mode: st-reload regenerates cache when version changes" {
    # First load
    run zsh -c "cd $HOME && SHELL_TOOLS_MINIMAL=1 source $HOME/.shell-tools/plugin.zsh"
    assert_success

    # Get original cache timestamp (cross-platform)
    if stat -f %m "$HOME/.shell-tools/cache/init-minimal.zsh" &>/dev/null; then
        CACHE_TIME=$(stat -f %m "$HOME/.shell-tools/cache/init-minimal.zsh")
    else
        CACHE_TIME=$(stat -c %Y "$HOME/.shell-tools/cache/init-minimal.zsh")
    fi

    sleep 1

    # Change VERSION to force regeneration
    echo "99.99.99" > "$HOME/.shell-tools/VERSION"

    # Reload (should regenerate cache due to version change)
    run zsh -c "cd $HOME && SHELL_TOOLS_MINIMAL=1 source $HOME/.shell-tools/plugin.zsh && st-reload"
    assert_success

    # Cache should be newer
    if stat -f %m "$HOME/.shell-tools/cache/init-minimal.zsh" &>/dev/null; then
        NEW_CACHE_TIME=$(stat -f %m "$HOME/.shell-tools/cache/init-minimal.zsh")
    else
        NEW_CACHE_TIME=$(stat -c %Y "$HOME/.shell-tools/cache/init-minimal.zsh")
    fi
    assert [ "$NEW_CACHE_TIME" -gt "$CACHE_TIME" ]
}

@test "Minimal mode: cache version matches VERSION file" {
    run zsh -c "cd $HOME && SHELL_TOOLS_MINIMAL=1 source $HOME/.shell-tools/plugin.zsh"
    assert_success

    local version=$(cat "$HOME/.shell-tools/VERSION")
    local cached_version=$(cat "$HOME/.shell-tools/cache/.version-minimal")
    [[ "$version" == "$cached_version" ]]
}

@test "Minimal mode: SHELL_TOOLS_MINIMAL is exported for subshells" {
    # When set before sourcing, minimal mode exports SHELL_TOOLS_MINIMAL=1 for subshells
    local result
    result=$(zsh -c "cd $HOME && export SHELL_TOOLS_MINIMAL=1 && source $HOME/.shell-tools/plugin.zsh && echo \$SHELL_TOOLS_MINIMAL" 2>/dev/null)
    [[ "$result" == "1" ]]
}

@test "Minimal mode: _st_is_minimal_mode function works" {
    run zsh -c "cd $HOME && source $HOME/.shell-tools/lib/core.zsh && SHELL_TOOLS_MINIMAL=1 && _st_is_minimal_mode && echo yes"
    assert_success
    assert_output "yes"
}

@test "Normal mode: regular user without env var gets full mode" {
    run zsh -c "cd $HOME && source $HOME/.shell-tools/plugin.zsh && st-version"
    assert_success
    refute_output --partial "(minimal)"
}

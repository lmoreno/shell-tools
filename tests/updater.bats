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

@test "Updater: st-update command exists" {
    run zsh -c "source $HOME/.shell-tools/plugin.zsh && type st-update"
    assert_success
}

@test "Updater: update check respects 'never' setting" {
    export SHELL_TOOLS_UPDATE_CHECK="never"

    # Source and reload - should not check for updates
    run zsh -c "source $HOME/.shell-tools/plugin.zsh && st-reload"

    # Should not create update check cache
    assert [ ! -f "$HOME/.shell-tools/cache/.last_update_check" ]
}

@test "Updater: version comparison works correctly" {
    # Test semantic version comparison
    run zsh -c "source $HOME/.shell-tools/plugin.zsh && _st_version_gt 'v2.1.0' 'v2.0.0'"
    assert_success

    run zsh -c "source $HOME/.shell-tools/plugin.zsh && _st_version_gt 'v2.0.0' 'v2.1.0'"
    assert_failure
}

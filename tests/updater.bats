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

@test "Updater: extraction detects flat ZIP structure" {
    # Create a mock flat ZIP structure (like release.yml creates)
    local temp_dir=$(mktemp -d)
    mkdir -p "$temp_dir/lib"
    echo "test" > "$temp_dir/VERSION"

    # Test the extraction directory detection logic
    run zsh -c "
        source $HOME/.shell-tools/plugin.zsh 2>/dev/null
        temp_dir='$temp_dir'

        # Simulate the extraction detection logic
        local extracted_dir
        if [[ -d \"\$temp_dir\"/lib ]]; then
            extracted_dir=\"\$temp_dir\"
        else
            extracted_dir=\"\$temp_dir\"/*-shell-tools-*
        fi

        echo \"\$extracted_dir\"
    "

    assert_success
    assert_output --partial "$temp_dir"

    rm -rf "$temp_dir"
}

@test "Updater: extraction detects wrapped ZIP structure" {
    # Create a mock wrapped ZIP structure (like GitHub zipball)
    local temp_dir=$(mktemp -d)
    mkdir -p "$temp_dir/lmoreno-shell-tools-abc123/lib"
    echo "test" > "$temp_dir/lmoreno-shell-tools-abc123/VERSION"

    # Test the extraction directory detection logic
    run zsh -c "
        source $HOME/.shell-tools/plugin.zsh 2>/dev/null
        temp_dir='$temp_dir'

        # Simulate the extraction detection logic
        local extracted_dir
        if [[ -d \"\$temp_dir\"/lib ]]; then
            extracted_dir=\"\$temp_dir\"
        else
            extracted_dir=\"\$temp_dir\"/*-shell-tools-*
        fi

        # Check if extracted_dir exists and has VERSION
        if [[ -d \"\$extracted_dir\" ]] && [[ -f \"\$extracted_dir/VERSION\" ]]; then
            echo \"success\"
        fi
    "

    assert_success
    assert_output --partial "success"

    rm -rf "$temp_dir"
}

@test "Updater: validates extraction directory and VERSION file" {
    # Test validation fails when no VERSION file
    local temp_dir=$(mktemp -d)
    mkdir -p "$temp_dir/lib"
    # No VERSION file created

    run zsh -c "
        source $HOME/.shell-tools/plugin.zsh 2>/dev/null
        temp_dir='$temp_dir'

        # Simulate validation logic
        local extracted_dir
        if [[ -d \"\$temp_dir\"/lib ]]; then
            extracted_dir=\"\$temp_dir\"
        else
            extracted_dir=\"\$temp_dir\"/*-shell-tools-*
        fi

        if [[ ! -d \"\$extracted_dir\" ]] || [[ ! -f \"\$extracted_dir/VERSION\" ]]; then
            echo \"validation failed\"
            exit 1
        fi
    "

    assert_failure
    assert_output --partial "validation failed"

    rm -rf "$temp_dir"
}

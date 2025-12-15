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

@test "Updater: extracts asset URL from release JSON using awk" {
    # Create mock GitHub API JSON response
    local mock_json='
{
  "tag_name": "v2.5.7",
  "assets": [
    {
      "name": "shell-tools.zip",
      "browser_download_url": "https://github.com/lmoreno/shell-tools/releases/download/v2.5.7/shell-tools.zip"
    }
  ]
}
'

    # Test the awk extraction logic
    run bash -c "
        echo '$mock_json' | awk '
            /\"name\": *\"shell-tools.zip\"/ {
                asset_block = 1;
                next;
            }
            asset_block == 1 {
                if (/\"browser_download_url\":/) {
                    sub(/.*\"browser_download_url\": \"/, \"\");
                    sub(/\".*/, \"\");
                    print;
                    asset_block = 0;
                }
            }
        '
    "

    assert_success
    assert_output "https://github.com/lmoreno/shell-tools/releases/download/v2.5.7/shell-tools.zip"
}

@test "Updater: fails gracefully when asset not found in JSON" {
    local mock_json='
{
  "tag_name": "v2.5.7",
  "assets": [
    {
      "name": "other-file.zip",
      "browser_download_url": "https://example.com/other.zip"
    }
  ]
}
'

    # Should return empty when shell-tools.zip not found
    run bash -c "
        echo '$mock_json' | awk '
            /\"name\": *\"shell-tools.zip\"/ {
                asset_block = 1;
                next;
            }
            asset_block == 1 {
                if (/\"browser_download_url\":/) {
                    sub(/.*\"browser_download_url\": \"/, \"\");
                    sub(/\".*/, \"\");
                    print;
                    asset_block = 0;
                }
            }
        '
    "

    assert_success
    assert_output ""
}

@test "Updater: extraction detects flat ZIP structure" {
    # Create a mock flat ZIP structure (release assets always have flat structure)
    local temp_dir=$(mktemp -d)
    mkdir -p "$temp_dir/lib"
    echo "test" > "$temp_dir/VERSION"

    # Test validation of flat structure
    run zsh -c "
        source $HOME/.shell-tools/plugin.zsh >/dev/null 2>&1
        temp_dir='$temp_dir'

        # Simulate the extraction logic (always flat for release assets)
        local extracted_dir=\"\$temp_dir\"

        # Validate
        if [[ -d \"\$extracted_dir/lib\" ]] && [[ -f \"\$extracted_dir/VERSION\" ]]; then
            echo \"valid\"
        fi
    "

    assert_success
    assert_output "valid"

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

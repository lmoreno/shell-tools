#!/usr/bin/env bats

load 'test_helper'

setup() {
    common_setup

    # Create mock GitHub API response
    export MOCK_GITHUB_JSON='
{
  "tag_name": "v2.8.0",
  "assets": [
    {
      "name": "shell-tools.zip",
      "browser_download_url": "https://example.com/shell-tools.zip"
    }
  ]
}
'

    # Create a mock zip file with shell-tools structure
    MOCK_ZIP_DIR=$(mktemp -d)
    mkdir -p "$MOCK_ZIP_DIR/lib"
    mkdir -p "$MOCK_ZIP_DIR/modules"
    mkdir -p "$MOCK_ZIP_DIR/tools"
    echo "2.8.0" > "$MOCK_ZIP_DIR/VERSION"
    echo "# Mock plugin" > "$MOCK_ZIP_DIR/plugin.zsh"

    # Create the zip
    (cd "$MOCK_ZIP_DIR" && zip -q -r /tmp/mock-shell-tools.zip .)
    rm -rf "$MOCK_ZIP_DIR"

    # Create mock curl wrapper
    MOCK_CURL_SCRIPT="$TEST_TEMP_DIR/curl"
    cat > "$MOCK_CURL_SCRIPT" << 'EOF'
#!/bin/bash
# Mock curl for testing
if [[ "$*" == *"api.github.com"* ]]; then
    # Return mock GitHub API response
    echo "$MOCK_GITHUB_JSON"
elif [[ "$*" == *"-o"* ]]; then
    # Download mock zip
    output_file=$(echo "$@" | grep -o -- '-o [^ ]*' | cut -d' ' -f2)
    cp /tmp/mock-shell-tools.zip "$output_file"
else
    # Fallback to real curl
    /usr/bin/curl "$@"
fi
EOF
    chmod +x "$MOCK_CURL_SCRIPT"
    export PATH="$TEST_TEMP_DIR:$PATH"
}

teardown() {
    # Cleanup mock files
    rm -f /tmp/mock-shell-tools.zip

    # Standard teardown
    if [[ -d "$TEST_TEMP_DIR" ]]; then
        rm -rf "$TEST_TEMP_DIR"
    fi
}

@test "Installation: download and install latest release" {
    # Run the install script from the project root
    run bash "$PROJECT_ROOT/install.sh"

    # Assert success
    assert_success

    # Assert installation directory exists
    assert [ -d "$HOME/.shell-tools" ]
    assert [ -f "$HOME/.shell-tools/plugin.zsh" ]

    # Assert .zshrc was modified
    run grep "source ~/.shell-tools/plugin.zsh" "$HOME/.zshrc"
    assert_success
}

@test "Installation: verify exclusions (clean install)" {
    run bash "$PROJECT_ROOT/install.sh"
    assert_success

    # Ensure excluded files are NOT present (these are in .gitignore, not in releases)
    assert [ ! -d "$HOME/.shell-tools/.github" ]
    assert [ ! -f "$HOME/.shell-tools/.gitignore" ]
    assert [ ! -f "$HOME/.shell-tools/CLAUDE.md" ]
}

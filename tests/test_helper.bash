# Load libraries
load 'libs/bats-support/load'
load 'libs/bats-assert/load'

# Global setup for all tests
common_setup() {
    # Create a safe sandbox directory
    TEST_TEMP_DIR="$(mktemp -d)"
    export HOME="$TEST_TEMP_DIR"
    export ZDOTDIR="$TEST_TEMP_DIR"

    # Create a dummy .zshrc
    touch "$HOME/.zshrc"

    # Project root (assuming tests/ is one level deep)
    PROJECT_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
    export PROJECT_ROOT

    # Source files are in src/ during development
    SRC_ROOT="$PROJECT_ROOT/src"
    export SRC_ROOT

    # Mock curl to return current VERSION for GitHub API calls
    # This prevents update prompts from hanging tests
    local current_version
    current_version=$(cat "$SRC_ROOT/VERSION" | tr -d '[:space:]')

    mkdir -p "$TEST_TEMP_DIR/bin"
    cat > "$TEST_TEMP_DIR/bin/curl" << EOF
#!/bin/bash
# Mock curl for tests - returns current version for GitHub API
if [[ "\$*" == *"api.github.com"*"releases/latest"* ]]; then
    echo '{"tag_name":"v${current_version}"}'
    echo "200"
else
    /usr/bin/curl "\$@"
fi
EOF
    chmod +x "$TEST_TEMP_DIR/bin/curl"
    export PATH="$TEST_TEMP_DIR/bin:$PATH"
}

teardown() {
    # Cleanup sandbox
    if [[ -d "$TEST_TEMP_DIR" ]]; then
        rm -rf "$TEST_TEMP_DIR"
    fi
}

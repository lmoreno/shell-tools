#!/bin/bash

HOOK_DIR=".git/hooks"
PRE_COMMIT="$HOOK_DIR/pre-commit"

echo "Setting up git hooks..."
mkdir -p "$HOOK_DIR"

cat > "$PRE_COMMIT" << 'EOF'
#!/bin/bash

# Validate VERSION first (fast fail)
echo "🔍 Validating VERSION file..."
./scripts/validate-version.sh
if [ $? -ne 0 ]; then
    echo "❌ VERSION validation failed. Commit aborted."
    exit 1
fi

# Run tests
echo "🏃 Running pre-commit tests..."
./tests/run tests/
EXIT_CODE=$?

if [ $EXIT_CODE -ne 0 ]; then
    echo "❌ Tests failed. Commit aborted."
    exit 1
fi

echo "✅ All checks passed."
exit 0
EOF

chmod +x "$PRE_COMMIT"
echo "✅ Pre-commit hook installed."

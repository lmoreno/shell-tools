#!/bin/bash
# Pre-commit hook logic - called from .git/hooks/pre-commit

# Validate VERSION first (fast fail)
echo "🔍 Validating VERSION file..."
./scripts/validate-version.sh
if [ $? -ne 0 ]; then
    echo "❌ VERSION validation failed. Commit aborted."
    exit 1
fi

# Run tests
echo "🏃 Running pre-commit tests..."
make test
EXIT_CODE=$?

if [ $EXIT_CODE -ne 0 ]; then
    echo "❌ Tests failed. Commit aborted."
    exit 1
fi

echo "✅ All checks passed."
exit 0

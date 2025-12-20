#!/bin/bash
set -e

VERSION_FILE="src/VERSION"

# Check file exists
if [ ! -f "$VERSION_FILE" ]; then
  echo "ERROR: $VERSION_FILE not found"
  exit 1
fi

# Read and clean version
VERSION=$(cat "$VERSION_FILE" | tr -d '[:space:]')

# Validate semver format (MAJOR.MINOR.PATCH, no 'v' prefix)
if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "ERROR: Invalid semver format in $VERSION_FILE: $VERSION"
  echo "Expected format: MAJOR.MINOR.PATCH (e.g., 2.7.2)"
  exit 1
fi

echo "✓ Valid semver format: $VERSION"
exit 0

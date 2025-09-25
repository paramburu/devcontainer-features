#!/bin/bash
set -e

# Import test library bundled with the devcontainer CLI
source dev-container-features-test-lib

# Check granted is installed
check "granted installed" bash -lc "command -v granted"

# Check version command works
check "granted version" bash -lc "granted --version >/dev/null 2>&1"

# Check config copied when provided in scenario (see scenarios.json)
if [ -f "/home/vscode/.granted/config" ]; then
  check "config copied" bash -lc "grep -q 'test-config' /home/vscode/.granted/config"
else
  echo "Note: config file not present in this scenario"
fi

reportResults

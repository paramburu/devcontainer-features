#!/bin/sh
set -e

echo "Activating feature 'granted'"

# Options (exported by the devcontainer tooling)
# Per spec, options are exposed as capitalized, sanitized env vars.
# completionShell -> COMPLETIONSHELL (fallback COMPLETION_SHELL),
# configSource -> CONFIGSOURCE (fallback CONFIG_SOURCE),
# configTargetPath -> CONFIGTARGETPATH (fallback CONFIG_TARGET_PATH)
COMPLETION_SHELL=${COMPLETIONSHELL:-${COMPLETION_SHELL:-}}
CONFIG_SOURCE=${CONFIGSOURCE:-${CONFIG_SOURCE:-}}
CONFIG_TARGET_PATH=${CONFIGTARGETPATH:-${CONFIG_TARGET_PATH:-}}

# Resolve remote user and home provided by features runtime
EFFECTIVE_USER=${_REMOTE_USER:-root}
EFFECTIVE_HOME=${_REMOTE_USER_HOME:-/root}

# If configTargetPath uses the provided variable, substitute now
if [ -n "$CONFIG_TARGET_PATH" ]; then
    CONFIG_TARGET_PATH=$(echo "$CONFIG_TARGET_PATH" | sed "s|\${_REMOTE_USER_HOME}|${EFFECTIVE_HOME}|g")
fi

echo "Completion shell: ${COMPLETION_SHELL:-none}"
echo "Config source: ${CONFIG_SOURCE:-<none>}"
echo "Config target path: ${CONFIG_TARGET_PATH:-<none>}"

# Ensure prerequisites
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y --no-install-recommends gpg wget ca-certificates
update-ca-certificates || true

# Setup Common Fate APT repository and key
if [ ! -f /usr/share/keyrings/common-fate-linux.gpg ]; then
    wget -O- https://apt.releases.commonfate.io/gpg | gpg --dearmor -o /usr/share/keyrings/common-fate-linux.gpg
fi

REPO_FILE="/etc/apt/sources.list.d/common-fate.list"
REPO_LINE="deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/common-fate-linux.gpg] https://apt.releases.commonfate.io stable main"
if [ ! -f "$REPO_FILE" ] || ! grep -Fxq "$REPO_LINE" "$REPO_FILE"; then
    echo "$REPO_LINE" | tee "$REPO_FILE" >/dev/null
fi

apt-get update -y
apt-get install -y granted

# Configure granted config file if provided
if [ -n "$CONFIG_SOURCE" ] && [ -f "$CONFIG_SOURCE" ]; then
    TARGET_DIR=$(dirname "$CONFIG_TARGET_PATH")
    mkdir -p "$TARGET_DIR"
    cp "$CONFIG_SOURCE" "$CONFIG_TARGET_PATH"
    chown -R "$EFFECTIVE_USER":"$EFFECTIVE_USER" "$TARGET_DIR" || true
fi

# Install shell completion using Granted's built-in installer
if [ -n "$COMPLETION_SHELL" ]; then
    case "$COMPLETION_SHELL" in
        bash|zsh|fish)
            # Let 'granted' manage completion installation for the selected shell
            granted completion -s "$COMPLETION_SHELL" >/dev/null 2>&1 || true
            ;;
        *)
            echo "Unknown shell '$COMPLETION_SHELL', skipping completion"
            ;;
    esac
fi

# Basic smoke test
if command -v granted >/dev/null 2>&1; then
    echo "granted version: $(granted --version || true)"
else
    echo "Warning: granted not found on PATH after installation" >&2
fi

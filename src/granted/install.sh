#!/bin/sh
set -e

# Simple logger to /var/log
LOG_DIR="/var/log"
LOG_FILE="$LOG_DIR/granted-feature.log"
log() {
    echo "[granted-feature] $1" | tee -a "$LOG_FILE"
}

log "Activating feature 'granted'"

# Options (exported by the devcontainer tooling)
# Per spec, options are exposed as capitalized, sanitized env vars.
# completionShell -> COMPLETIONSHELL (fallback COMPLETION_SHELL),
# configSource -> CONFIGSOURCE (fallback CONFIG_SOURCE),
# configTargetPath -> CONFIGTARGETPATH (fallback CONFIG_TARGET_PATH)
# hostAwsMountPath -> HOSTAWSMOUNTPATH (fallback HOST_AWS_MOUNT_PATH)
COMPLETION_SHELL=${COMPLETIONSHELL:-${COMPLETION_SHELL:-}}
CONFIG_SOURCE=${CONFIGSOURCE:-${CONFIG_SOURCE:-}}
CONFIG_TARGET_PATH=${CONFIGTARGETPATH:-${CONFIG_TARGET_PATH:-}}
HOST_AWS_MOUNT_PATH=${HOSTAWSMOUNTPATH:-${HOST_AWS_MOUNT_PATH:-}}

# Resolve remote user and home provided by features runtime
EFFECTIVE_USER=${_REMOTE_USER:-root}
EFFECTIVE_HOME=${_REMOTE_USER_HOME:-/root}

# If configTargetPath uses the provided variable, substitute now
if [ -n "$CONFIG_TARGET_PATH" ]; then
    CONFIG_TARGET_PATH=$(echo "$CONFIG_TARGET_PATH" | sed "s|\${_REMOTE_USER_HOME}|${EFFECTIVE_HOME}|g")
fi

# Resolve HOST_AWS_MOUNT_PATH if it includes ${_REMOTE_USER_HOME}
if [ -n "$HOST_AWS_MOUNT_PATH" ]; then
    HOST_AWS_MOUNT_PATH=$(echo "$HOST_AWS_MOUNT_PATH" | sed "s|\${_REMOTE_USER_HOME}|${EFFECTIVE_HOME}|g")
fi

log "Environment snapshot:"
log "  _REMOTE_USER=${_REMOTE_USER}"
log "  _REMOTE_USER_HOME=${_REMOTE_USER_HOME}"
log "  EFFECTIVE_USER=${EFFECTIVE_USER}"
log "  EFFECTIVE_HOME=${EFFECTIVE_HOME}"
log "  COMPLETION_SHELL=${COMPLETION_SHELL}"
log "  CONFIG_SOURCE=${CONFIG_SOURCE}"
log "  CONFIG_TARGET_PATH=${CONFIG_TARGET_PATH}"
log "  HOST_AWS_MOUNT_PATH=${HOST_AWS_MOUNT_PATH}"

# Ensure prerequisites
export DEBIAN_FRONTEND=noninteractive
log "Installing prerequisites (gpg, wget, ca-certificates)"
apt-get update -y >>"$LOG_FILE" 2>&1
apt-get install -y --no-install-recommends gpg wget ca-certificates >>"$LOG_FILE" 2>&1
update-ca-certificates >>"$LOG_FILE" 2>&1 || true

# Setup Common Fate APT repository and key
if [ ! -f /usr/share/keyrings/common-fate-linux.gpg ]; then
    log "Installing Common Fate APT GPG key"
    wget -O- https://apt.releases.commonfate.io/gpg | gpg --dearmor -o /usr/share/keyrings/common-fate-linux.gpg
else
    log "GPG key already present"
fi

REPO_FILE="/etc/apt/sources.list.d/common-fate.list"
REPO_LINE="deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/common-fate-linux.gpg] https://apt.releases.commonfate.io stable main"
if [ ! -f "$REPO_FILE" ] || ! grep -Fxq "$REPO_LINE" "$REPO_FILE"; then
    log "Configuring Common Fate APT repository"
    echo "$REPO_LINE" | tee "$REPO_FILE" >/dev/null
else
    log "APT repository already configured"
fi

log "Installing granted"
apt-get update -y >>"$LOG_FILE" 2>&1
apt-get install -y granted >>"$LOG_FILE" 2>&1

# Configure granted config file if provided
if [ -n "$CONFIG_SOURCE" ] && [ -f "$CONFIG_SOURCE" ]; then
    log "Copying config from $CONFIG_SOURCE to $CONFIG_TARGET_PATH"
    TARGET_DIR=$(dirname "$CONFIG_TARGET_PATH")
    mkdir -p "$TARGET_DIR"
    cp "$CONFIG_SOURCE" "$CONFIG_TARGET_PATH"
    chown -R "$EFFECTIVE_USER":"$EFFECTIVE_USER" "$TARGET_DIR" || true
else
    log "No config copied (source missing or not specified)"
fi

# If a host AWS mount path exists, symlink it to the user's ~/.aws if not present
if [ -n "$HOST_AWS_MOUNT_PATH" ] && [ -d "$HOST_AWS_MOUNT_PATH" ]; then
    log "Setting up ~/.aws symlink to host mount: $HOST_AWS_MOUNT_PATH"
    USER_AWS_DIR="${EFFECTIVE_HOME}/.aws"
    if [ ! -e "$USER_AWS_DIR" ]; then
        ln -s "$HOST_AWS_MOUNT_PATH" "$USER_AWS_DIR"
        chown -h "$EFFECTIVE_USER":"$EFFECTIVE_USER" "$USER_AWS_DIR" || true
    else
        log "~/.aws already exists, skipping symlink"
    fi
fi

# Install shell completion using Granted's built-in installer as the effective user
if [ -n "$COMPLETION_SHELL" ]; then
    case "$COMPLETION_SHELL" in
        bash|zsh|fish)
            log "Installing completions for $COMPLETION_SHELL as $EFFECTIVE_USER"
            if id "$EFFECTIVE_USER" >/dev/null 2>&1; then
                su - "$EFFECTIVE_USER" -c "granted completion -s $COMPLETION_SHELL >/dev/null 2>&1 || true"
            else
                log "Effective user $EFFECTIVE_USER not found; skipping completion install"
            fi
            ;;
        *)
            log "Unknown shell '$COMPLETION_SHELL', skipping completion"
            ;;
    esac
fi

# Basic smoke test
if command -v granted >/dev/null 2>&1; then
    log "granted version: $(granted --version || true)"
else
    log "Warning: granted not found on PATH after installation"
fi

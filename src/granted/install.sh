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
COMPLETION_SHELL=${COMPLETIONSHELL:-${COMPLETION_SHELL:-}}

# Resolve remote user and home provided by features runtime
EFFECTIVE_USER=${_REMOTE_USER:-root}
EFFECTIVE_HOME=${_REMOTE_USER_HOME:-/root}

log "Environment snapshot:"
log "  _REMOTE_USER=${_REMOTE_USER}"
log "  _REMOTE_USER_HOME=${_REMOTE_USER_HOME}"
log "  EFFECTIVE_USER=${EFFECTIVE_USER}"
log "  EFFECTIVE_HOME=${EFFECTIVE_HOME}"
log "  COMPLETION_SHELL=${COMPLETION_SHELL}"

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

# Ensure ~/.aws points to the mounted host directory if present
MOUNTED_AWS_DIR="/opt/host-aws"
USER_AWS_DIR="${EFFECTIVE_HOME}/.aws"
if [ -d "$MOUNTED_AWS_DIR" ] || [ -L "$USER_AWS_DIR" ] || [ ! -e "$USER_AWS_DIR" ]; then
    log "Ensuring ${USER_AWS_DIR} symlink to ${MOUNTED_AWS_DIR}"
    mkdir -p "$(dirname "$USER_AWS_DIR")"
    if [ -L "$USER_AWS_DIR" ]; then
        ln -sfn "$MOUNTED_AWS_DIR" "$USER_AWS_DIR"
        log "Updated existing symlink ${USER_AWS_DIR} -> ${MOUNTED_AWS_DIR}"
    elif [ -e "$USER_AWS_DIR" ]; then
        log "~/.aws exists and is not a symlink; leaving as-is"
    else
        ln -s "$MOUNTED_AWS_DIR" "$USER_AWS_DIR"
        log "Created symlink ${USER_AWS_DIR} -> ${MOUNTED_AWS_DIR}"
    fi
    chown -h "$EFFECTIVE_USER":"$EFFECTIVE_USER" "$USER_AWS_DIR" || true
else
    log "Mount target not present at ${MOUNTED_AWS_DIR}; skipping ~/.aws symlink"
fi

# Basic smoke test
if command -v granted >/dev/null 2>&1; then
    log "$(granted --version || true)"
else
    log "Warning: granted not found on PATH after installation"
fi

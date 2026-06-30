#!/bin/sh
set -e

EFFECTIVE_USER=${_REMOTE_USER:-root}
EFFECTIVE_HOME=${_REMOTE_USER_HOME:-}

if [ -z "$EFFECTIVE_HOME" ]; then
	EFFECTIVE_HOME=$(getent passwd "$EFFECTIVE_USER" | cut -d: -f6 || true)
fi

if [ -z "$EFFECTIVE_HOME" ]; then
	EFFECTIVE_HOME="/root"
fi

# Determine writable log directory
if [ "$EFFECTIVE_USER" != "root" ]; then
	LOG_DIR="$EFFECTIVE_HOME/.local/log"
	mkdir -p "$LOG_DIR"
else
	LOG_DIR="/var/log"
fi
LOG_FILE="$LOG_DIR/personal-feature.log"

log() {
	echo "[personal-feature] $1" | tee -a "$LOG_FILE" 2>/dev/null || echo "[personal-feature] $1"
}

log "Activating feature 'personal'"
log "Environment snapshot:"
log "  _REMOTE_USER=${_REMOTE_USER}"
log "  _REMOTE_USER_HOME=${_REMOTE_USER_HOME}"
log "  EFFECTIVE_USER=${EFFECTIVE_USER}"
log "  EFFECTIVE_HOME=${EFFECTIVE_HOME}"

mkdir -p "$EFFECTIVE_HOME"

MOUNT_BASE="/opt/host-home"

if [ "${PERSONAL_FEATURE_POST_CREATE:-0}" != "1" ]; then
	log "Mount-dependent setup deferred until postCreateCommand"
	log "Personal feature setup completed"
	exit 0
fi

# Retry loop: mounts may not be ready immediately
RETRY_MAX=30
RETRY_WAIT=1
RETRIES=0

while [ ! -d "$MOUNT_BASE" ] && [ $RETRIES -lt $RETRY_MAX ]; do
	RETRIES=$((RETRIES + 1))
	log "Waiting for mount base ($RETRIES/$RETRY_MAX)..."
	sleep "$RETRY_WAIT"
done

if [ ! -d "$MOUNT_BASE" ]; then
	log "Mount base $MOUNT_BASE not found after ${RETRY_MAX}s; nothing to link"
	log "Hint: verify host source paths exist and that devcontainer mounts are enabled in this runtime"
	log "Personal feature setup completed"
	exit 0
fi

for source_path in "$MOUNT_BASE"/.* "$MOUNT_BASE"/*; do
	if [ ! -e "$source_path" ] && [ ! -L "$source_path" ]; then
		continue
	fi

	dotfile=$(basename "$source_path")
	case "$dotfile" in
		.|..)
			continue
			;;
	esac

	target_path="$EFFECTIVE_HOME/$dotfile"

	if [ "$source_path" = "$target_path" ]; then
		continue
	fi

	if [ -L "$target_path" ]; then
		ln -sfn "$source_path" "$target_path"
		log "Updated symlink $target_path -> $source_path"
	elif [ -e "$target_path" ]; then
		log "$target_path exists and is not a symlink; leaving as-is"
	else
		ln -s "$source_path" "$target_path"
		log "Created symlink $target_path -> $source_path"
	fi

	chown -h "$EFFECTIVE_USER":"$EFFECTIVE_USER" "$target_path" 2>/dev/null || true
done

log "Personal feature setup completed"

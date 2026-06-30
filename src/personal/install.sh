#!/bin/sh
set -e

LOG_DIR="/var/log"
LOG_FILE="$LOG_DIR/personal-feature.log"

log() {
	echo "[personal-feature] $1" | tee -a "$LOG_FILE"
}

EFFECTIVE_USER=${_REMOTE_USER:-root}
EFFECTIVE_HOME=${_REMOTE_USER_HOME:-}

if [ -z "$EFFECTIVE_HOME" ]; then
	EFFECTIVE_HOME=$(getent passwd "$EFFECTIVE_USER" | cut -d: -f6 || true)
fi

if [ -z "$EFFECTIVE_HOME" ]; then
	EFFECTIVE_HOME="/root"
fi

log "Activating feature 'personal'"
log "Environment snapshot:"
log "  _REMOTE_USER=${_REMOTE_USER}"
log "  _REMOTE_USER_HOME=${_REMOTE_USER_HOME}"
log "  EFFECTIVE_USER=${EFFECTIVE_USER}"
log "  EFFECTIVE_HOME=${EFFECTIVE_HOME}"

mkdir -p "$EFFECTIVE_HOME"

MOUNT_BASE="/opt/host-home"

if [ ! -d "$MOUNT_BASE" ]; then
	log "Mount base $MOUNT_BASE not found; nothing to link"
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

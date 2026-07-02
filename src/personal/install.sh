#!/bin/sh
set -e

EFFECTIVE_USER=${_REMOTE_USER:-}

# If not set by feature infrastructure, discover the first non-system user (UID >= 1000)
if [ -z "$EFFECTIVE_USER" ]; then
	EFFECTIVE_USER=$(getent passwd | awk -F: '$3 >= 1000 {print $1; exit}' || true)
fi

# Final fallback
if [ -z "$EFFECTIVE_USER" ]; then
	EFFECTIVE_USER="root"
fi

EFFECTIVE_HOME=${_REMOTE_USER_HOME:-}

if [ -z "$EFFECTIVE_HOME" ]; then
	EFFECTIVE_HOME=$(getent passwd "$EFFECTIVE_USER" | cut -d: -f6 || true)
fi

if [ -z "$EFFECTIVE_HOME" ]; then
	EFFECTIVE_HOME="/root"
fi

mkdir -p "$EFFECTIVE_HOME"

# Explicit list of dotfiles/directories to symlink from /opt/host-home
DOTFILES=".codex .claude .copilot .agents .viminfo .npm .npmrc .vim .vimrc .oh-my-zsh .zprofile .zshenv .zshrc .dotfiles"

MOUNT_BASE="/opt/host-home"

for dotfile in $DOTFILES; do
	source_path="$MOUNT_BASE/$dotfile"
	target_path="$EFFECTIVE_HOME/$dotfile"

	ln -sfn "$source_path" "$target_path"
	chown -h "$EFFECTIVE_USER":"$EFFECTIVE_USER" "$target_path" 2>/dev/null || true
done



## Personal (personal)

Mount selected host dotfiles into `/opt/host-home` and symlink them into the
devcontainer user's home directory during feature installation.

## Example Usage

```json
"features": {
  "ghcr.io/paramburu/devcontainer-features/personal:1": {}
}
```

## How it works

- Host paths are bind-mounted to `/opt/host-home/<name>`.
- During install, the script discovers entries dynamically under
  `/opt/host-home`.
- Each discovered entry is symlinked to `${_REMOTE_USER_HOME:-$HOME}/<name>`.

## Safety behavior

- Existing symlinks in the user home are updated to point to the mounted path.
- Existing non-symlink files/directories are left unchanged.
- Missing mounts are skipped.

## Mounted entries in this feature

- `${localEnv:HOME}/.codex` -> `/opt/host-home/.codex`
- `${localEnv:HOME}/.claude` -> `/opt/host-home/.claude`
- `${localEnv:HOME}/.copilot` -> `/opt/host-home/.copilot`
- `${localEnv:HOME}/.agents` -> `/opt/host-home/.agents`
- `${localEnv:HOME}/.viminfo` -> `/opt/host-home/.viminfo`
- `${localEnv:HOME}/.npm` -> `/opt/host-home/.npm`
- `${localEnv:HOME}/.npmrc` -> `/opt/host-home/.npmrc`
- `${localEnv:HOME}/.vim` -> `/opt/host-home/.vim`
- `${localEnv:HOME}/.vimrc` -> `/opt/host-home/.vimrc`
- `${localEnv:HOME}/.oh-my-zsh` -> `/opt/host-home/.oh-my-zsh`
- `${localEnv:HOME}/.zprofile` -> `/opt/host-home/.zprofile`
- `${localEnv:HOME}/.zshenv` -> `/opt/host-home/.zshenv`
- `${localEnv:HOME}/.zshrc` -> `/opt/host-home/.zshrc`


# Granted (Common Fate) (granted)

Installs the 'granted' CLI from Common Fate APT repository, optionally sets up shell completions and copies a config file.

## Example Usage

```json
"features": {
    "ghcr.io/paramburu/devcontainer-features/granted:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| completionShell | Shell to install completions for. | string | zsh |
| configSource | Path to a granted config file to copy from (inside the workspace/image). Leave as a non-existent path to skip copy. | string | .devcontainer/granted_config |
| configTargetPath | Absolute path where the granted config file will be placed inside the container. | string | ${_REMOTE_USER_HOME}/.granted/config |
| hostAwsMountPath | If set and exists, a directory where host ~/.aws is mounted. The installer will symlink ${_REMOTE_USER_HOME}/.aws to this path if ~/.aws does not already exist. | string | /opt/host-aws |



---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/paramburu/devcontainer-features/blob/main/src/granted/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._

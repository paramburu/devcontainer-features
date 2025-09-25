# Granted (Common Fate)

Installs the Common Fate "granted" CLI via the official APT repository, with optional shell completions and config file placement.

## Options

- completionShell: Shell to generate completions for. One of `bash`, `zsh`, `fish`. Default: `zsh`.
- configSource: Source path of a granted config file to copy into the container. Default: `.devcontainer/granted_config`.
- configTargetPath: Absolute path to write the config file to. Default: `${_REMOTE_USER_HOME}/.granted/config`.

## Example usage

```jsonc
{
  "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
  "features": {
    "granted": {
      "completionShell": "zsh",
      "configSource": ".devcontainer/granted_config",
      "configTargetPath": "/home/vscode/.granted/config"
    }
  }
}
```

This feature adds the Common Fate APT repository and installs the `granted` package. If `configSource` exists, it will be copied to `configTargetPath`. Shell completions are installed system-wide for the selected shell.

```bash
# Example manual checks inside container
which granted
granted --version
```

---

Based on: https://apt.releases.commonfate.io/

# Granted (Common Fate)

Installs the Common Fate "granted" CLI via the official APT repository, with optional shell completions and config file placement.

## Options

- completionShell: Shell to generate completions for. One of `bash`, `zsh`, `fish`. Default: `zsh`.
- configSource: Source path of a granted config file to copy into the container. Default: `.devcontainer/granted_config`.
- configTargetPath: Absolute path to write the config file to. Default: `${_REMOTE_USER_HOME}/.granted/config`.
- hostAwsMountPath: Directory where the host `~/.aws` is mounted inside the container. Default: `/opt/host-aws`.

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

## Mount host AWS config (recommended)

To let Granted use your host AWS config and credentials, bind-mount your host `~/.aws` into the container at a stable path, then the feature will symlink it to the effective remote user’s home (`${_REMOTE_USER_HOME}/.aws`).

Add this to your `devcontainer.json`:

```jsonc
{
  // ...
  "mounts": [
    "type=bind,source=${localEnv:HOME}/.aws,target=/opt/host-aws"
  ],
  "features": {
    "granted": {
      // optional: change if you mounted to a different path
      "hostAwsMountPath": "/opt/host-aws"
    }
  }
}
```

Why this pattern? The dev container mount target is evaluated before the feature runs and doesn’t have context for `${_REMOTE_USER_HOME}`. By mounting to a fixed location (default `/opt/host-aws`), the feature’s installer safely links it to `${_REMOTE_USER_HOME}/.aws` for whatever user your container ultimately uses.

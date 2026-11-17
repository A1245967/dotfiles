# dotfiles

Personal command-line configuration shared across machines.

## Included

- `bashrc`: Bash prompt, Git completion, color aliases, and helper functions.
- `install.sh`: Backs up the current `~/.bashrc` and links this repository's
  `bashrc` in its place.

## Install

Clone the repository, then run:

```sh
./install.sh
```

Start a new shell or load the configuration immediately with:

```sh
source ~/.bashrc
```

## Machine-specific settings

Keep secrets and machine-specific values out of this public repository. Use
environment variables or a separate, untracked local file for private values.


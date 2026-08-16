# Dotfiles

Bootstrap a new dev machine with a single command.

## Install

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/andresfelipemendez/dotfiles/main/install.sh)"
```

## What Gets Installed

| Category | Packages |
|----------|----------|
| **Core** | zsh, git, tmux, neovim, curl, htop, unzip, xclip, ripgrep, jq, node |
| **Languages / DB** | go (version-checked against nixpkgs/brew on every run), postgresql 18 (binaries only — no server is initialized or started) |
| **GitHub (latest)** | fzf, lazygit, fd, bat |
| **Official repos** | gh, Docker, 1Password, gcloud, kubectl |
| **Fonts** | SauceCodePro Nerd Font Mono — wired into ghostty, Ptyxis, and GNOME Terminal |
| **Shell** | Oh My Zsh |
| **AI** | Claude Code + [caveman](https://github.com/JuliusBrussee/caveman) plugin |

## Passwordless sudo via 1Password

`bin/sudo-askpass` is a `SUDO_ASKPASS` helper that reads the account password
from 1Password at call time, so unattended `sudo` never blocks on a prompt:

```sh
sudo -A apt-get update      # or: sudo --askpass ...
```

`.zshrc` exports `SUDO_ASKPASS` automatically once the helper is symlinked into
`~/.local/bin`. The password is never written to disk, shell history, argv, or
an environment variable — the helper prints it on stdout and sudo reads it
directly.

Setup:

1. Store the account password in 1Password at `op://Private/sudo/password`
   (override the reference with `SUDO_ASKPASS_OP_REF` if it lives elsewhere).
2. Sign in once per session: `eval $(op signin)`.

If `op` is missing or 1Password is locked, the helper falls back to a normal
terminal prompt rather than failing the command.

## Claude Code

Every machine gets Claude Code plus the caveman plugin, wired up automatically:

- `claude` installed to `~/.local/bin` if missing
- caveman marketplace added and plugin installed (`caveman@caveman`)
- default caveman mode written to `~/.claude/.caveman-active` (only if unset)
- caveman statusline pointed at the installed plugin version
- portable settings from `.claude/settings.base.json` deep-merged into
  `~/.claude/settings.json` with `jq` — machine-local hooks, permissions, and
  plugins are preserved

The plugin ships its own `SessionStart`/`UserPromptSubmit` hooks, so nothing
extra is registered for those. Every step is idempotent and non-fatal: if
Claude Code isn't logged in yet, the rest of the bootstrap still completes.

## Requirements

- Debian/Ubuntu (x86_64 or arm64)
- sudo access

## Post-Install

```bash
chsh -s $(which zsh)  # Set zsh as default
# Log out and back in
```

## Symlinks

```
~/.zshrc           → ~/dotfiles/.zshrc
~/.gitconfig       → ~/dotfiles/.gitconfig
~/.config/lazygit  → ~/dotfiles/.config/lazygit
```

## Re-run / Update

```bash
cd ~/dotfiles && ./install.sh
```

# Dotfiles

Bootstrap a new dev machine with a single command.

## Install

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/andresfelipemendez/dotfiles/main/install.sh)"
```

## What Gets Installed

| Category | Packages |
|----------|----------|
| **Core** | zsh, git, tmux, neovim, curl, htop, unzip, xclip, ripgrep |
| **GitHub (latest)** | fzf, lazygit, fd, bat |
| **Official repos** | gh, Docker, 1Password, gcloud, kubectl |
| **Shell** | Oh My Zsh |

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

OS="$(uname -s)"

install_package() {
    local package="$1"
    if command -v "$package" >/dev/null 2>&1; then
        return 0
    fi

    if [ "$OS" = "Darwin" ]; then
        brew install "$package"
    elif [ "$OS" = "Linux" ]; then
        if command -v apt-get >/dev/null 2>&1; then
            sudo apt-get install -y "$package"
        elif command -v dnf >/dev/null 2>&1; then
            sudo dnf install -y "$package"
        elif command -v pacman >/dev/null 2>&1; then
            sudo pacman -S --noconfirm "$package"
        else
            echo "Unknown package manager. Please install $package manually."
            return 1
        fi
    fi
}

install_package fzf

if [ "$OS" = "Darwin" ]; then
    if ! command -v hammerspoon >/dev/null 2>&1; then
        brew install --cask hammerspoon
    fi
fi

create_symlink() {
    local source="$1"
    local target="$2"
    local target_dir
    target_dir="$(dirname "$target")"

    if [ -L "$target" ] && [ "$(readlink "$target")" = "$source" ]; then
        return 0
    fi

    [ ! -d "$target_dir" ] && mkdir -p "$target_dir"
    [ -e "$target" ] && rm "$target"
    ln -s "$source" "$target"
}

if [ "$OS" = "Darwin" ]; then
    create_symlink ~/dotfiles/hammerspoon/init.lua ~/.hammerspoon/init.lua
fi
create_symlink ~/dotfiles/.zshrc ~/.zshrc
create_symlink ~/dotfiles/.gitconfig ~/.gitconfig
create_symlink ~/dotfiles/.tmux.conf ~/.tmux.conf
create_symlink ~/dotfiles/.config/lazygit ~/.config/lazygit
create_symlink ~/dotfiles/.config/ghostty ~/.config/ghostty
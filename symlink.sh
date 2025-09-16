if ! command -v fzf >/dev/null 2>&1; then
    brew install fzf
fi

if ! command -v hammerspoon >/dev/null 2>&1; then
    brew install --cask hammerspoon
fi

create_symlink() {
    local source="$1"
    local target="$2"
    
    if [ -L "$target" ] && [ "$(readlink "$target")" = "$source" ]; then
        return 0
    fi
    
    [ -e "$target" ] && rm "$target"
    ln -s "$source" "$target"
}

create_symlink ~/dotfiles/hammerspoon/init.lua ~/.hammerspoon/init.lua
create_symlink ~/dotfiles/.zshrc ~/.zshrc
create_symlink ~/dotfiles/.gitconfig ~/.gitconfig
create_symlink ~/dotfiles/.config/lazygit ~/.config/lazygit
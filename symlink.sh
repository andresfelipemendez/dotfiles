if ! command -v fzf >/dev/null 2>&1; then
    brew install fzf
fi

if ! command -v hammerspoon >/dev/null 2>&1; then
    brew install --cask hammerspoon
fi

[ -f ~/.hammerspoon/init.lua ] && rm ~/.hammerspoon/init.lua
[ -f ~/.zshrc ] && rm ~/.zshrc
[ -f ~/.gitconfig ] && rm ~/.gitconfig

ln -s ~/dotfiles/hammerspoon/init.lua ~/.hammerspoon/init.lua
ln -s ~/dotfiles/.zshrc ~/.zshrc
ln -s ~/dotfiles/.gitconfig ~/.gitconfig
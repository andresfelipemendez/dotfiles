# If you come from bash you might have to change your $PATH.
export PATH="$HOME/.local/bin:$PATH"
export PATH="/opt/homebrew/opt/openjdk@17/bin:$PATH"

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time Oh My Zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="robbyrussell"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git fzf you-should-use zsh-bat zsh-autosuggestions zsh-syntax-highlighting)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='nvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch $(uname -m)"

# Set personal aliases, overriding those provided by Oh My Zsh libs,
# plugins, and themes. Aliases can be placed here, though Oh My Zsh
# users are encouraged to define aliases within a top-level file in
# the $ZSH_CUSTOM folder, with .zsh extension. Examples:
# - $ZSH_CUSTOM/aliases.zsh
# - $ZSH_CUSTOM/macos.zsh
# For a full list of active aliases, run `alias`.
#
# Example aliases
alias zc="subl ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

source <(fzf --zsh)

# fzf configuration
export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border --inline-info"
export FZF_DEFAULT_COMMAND="fd --type f --hidden --follow --exclude .git"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_CTRL_T_OPTS="--preview 'bat --color=always --style=header,grid --line-range :300 {}'"
export FZF_CTRL_R_OPTS="--preview 'echo {}' --preview-window down:3:hidden --bind '?:toggle-preview'"

# Custom fzf keybindings
bindkey '^T' fzf-file-widget
bindkey '^R' fzf-history-widget
bindkey '^I' fzf-completion

# fd and bat aliases
alias cat='bat --pager=never --style=plain'
alias find='fd'
alias tree='fd --tree'

# Quick file search with fzf + fd
function ff() {
    fd --type f --hidden --follow --exclude .git | fzf --preview 'bat --color=always --style=header,grid --line-range :300 {}' | xargs -r nvim
}

# Added by LM Studio CLI (lms)
export PATH="$PATH:/Users/andres/.lmstudio/bin"
# End of LM Studio CLI section

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

if command -v gcloud >/dev/null 2>&1; then
    export PATH="$(gcloud info --format='value(installation.sdk_root)')/bin:$PATH"
else
    echo "gcloud is not installed or not in PATH"
fi

export PATH="/opt/homebrew/sbin:$PATH"
export PATH="/opt/homebrew/bin:$PATH"
export PATH="/Users/andres/flutter/bin:$PATH"

# Hiro GDK configuration
HIRO_REPO="${HIRO_REPO:-$HOME/Developer/hiro-gdk}"

# Git update - fetch and pull latest changes
unalias gu 2>/dev/null
function gu() {
    if ! git rev-parse --git-dir >/dev/null 2>&1; then
        echo "Not a git repository"; return 1
    fi
    git fetch && git pull
}

# Create new worktree from main branch
# Usage: nwt feature-name (am- prefix added to branch automatically)
function nwt() {
    if [[ -z "$1" ]]; then
        echo "Usage: nwt <branch-name>"; return 1
    fi
    if [[ ! -d "$HIRO_REPO/main" ]]; then
        echo "Repository main branch not found at $HIRO_REPO/main"; return 1
    fi
    local folder="${1#am-}"
    local branch="$1"
    [[ "$branch" != am-* ]] && branch="am-$branch"
    (cd "$HIRO_REPO/main" && git fetch && git pull) \
        && (cd "$HIRO_REPO/main" && git worktree add "../$folder" -b "$branch" main) \
        && cd "$HIRO_REPO/$folder"
}

# Checkout existing remote branch as worktree, build Hiro, and generate license
# Usage: cwt am-feature-name
function cwt() {
    if [[ -z "$1" ]]; then
        echo "Usage: cwt <branch-name>"; return 1
    fi
    if [[ ! -d "$HIRO_REPO/main" ]]; then
        echo "Repository main branch not found at $HIRO_REPO/main"; return 1
    fi
    if ! command -v docker >/dev/null 2>&1; then
        echo "Docker is not installed"; return 1
    fi
    local folder="${1#am-}"
    local branch="$1"
    local plugin_vsn
    plugin_vsn=$(cd "$HIRO_REPO/main" && task get-nakama-version 2>/dev/null || echo "3.35.1")
    (cd "$HIRO_REPO/main" && git fetch) \
        && (cd "$HIRO_REPO/main" && git worktree add "../$folder" "$branch") \
        && (cd "$HIRO_REPO/$folder/server" && docker run --platform "linux/arm64" --rm -w "/server" -v "$(pwd):/server" heroiclabs/nakama-pluginbuilder:"$plugin_vsn" build --buildmode=plugin -trimpath -o "./hiro-linux-arm64.bin") \
        && mkdir -p "$HIRO_REPO/$folder/ProjectTemplate/lib" \
        && cp "$HIRO_REPO/$folder/server/hiro-linux-arm64.bin" "$HIRO_REPO/$folder/ProjectTemplate/lib/" \
        && docker rm -f game_backend_nakama game_backend_postgres 2>/dev/null || true
    cd "$HIRO_REPO/$folder"
}

# Open new tmux session keeping current directory
function t() {
    if ! command -v tmux >/dev/null 2>&1; then
        echo "tmux is not installed"; return 1
    fi
    tmux new-session "cd '$PWD' && exec $SHELL"
}

# Stop all containers and prune Docker system
function docker-nuke() {
    echo "This will stop all containers and remove all Docker data."
    read -q "REPLY?Continue? [y/N] " || { echo; return 1; }
    echo
    docker stop $(docker ps -aq) 2>/dev/null || true
    docker system prune -a --volumes -f
}

# List all git worktrees in the Hiro repository
function list-worktrees() {
    (cd "$HIRO_REPO/main" && git worktree list)
}

# Remove a git worktree and its branch
# Usage: remove-worktree am-feature-name
function remove-worktree() {
    if [[ -z "$1" ]]; then
        echo "Usage: remove-worktree <branch-name>"; return 1
    fi
    local folder="${1#am-}"
    local branch="$1"
    if [[ ! -d "$HIRO_REPO/$folder" ]]; then
        echo "Worktree $folder does not exist"; return 1
    fi
    (cd "$HIRO_REPO/main" && git worktree remove "../$folder" && git branch -D "$branch")
}

# Navigate to Hiro main directory
function gdk() {
    cd "$HIRO_REPO/main"
}

# Navigate to a specific Hiro worktree
# Usage: goto-worktree am-feature-name
function goto-worktree() {
    if [[ -z "$1" ]]; then
        echo "Usage: goto-worktree <branch-name>"; return 1
    fi
    local folder="${1#am-}"
    if [[ ! -d "$HIRO_REPO/$folder" ]]; then
        echo "Worktree $folder does not exist"; return 1
    fi
    cd "$HIRO_REPO/$folder"
}

# Convert video file to mp3 audio
# Usage: v2mp3 video-file.mov
function v2mp3() {
    if [[ -z "$1" ]]; then
        echo "Usage: v2mp3 <video-file>"; return 1
    fi
    if ! command -v ffmpeg >/dev/null 2>&1; then
        echo "ffmpeg is not installed"; return 1
    fi
    local input="$1"
    local output="${input%.*}.mp3"
    if [[ ! -f "$input" ]]; then
        echo "File $input does not exist"; return 1
    fi
    ffmpeg -i "$input" -vn -ac 1 -ar 16000 -ab 64k -f mp3 "$output" \
        && echo "Converted $input to $output"
}

export VCPKG_ROOT=~/vcpkg
export PATH=$VCPKG_ROOT:$PATH
# Go and Zig paths
export PATH="/usr/local/go/bin:$PATH"
export PATH="$HOME/go/bin:$PATH"
# Zig is already in ~/.local/bin which is added at the top

export KUBECONFIG=$HOME/.kube/config
export EGOS=$HOME/Developer/egos-2000
export PATH=$PATH:$HOME/Developer/xpack-riscv-none-elf-gcc-14.2.0-3/bin
# Created by `pipx` on 2026-01-13 12:52:31
export PATH="$PATH:/Users/andres/.local/bin"

# opencode
export PATH=/Users/andres/.opencode/bin:$PATH
export XDG_CONFIG_HOME="$HOME/.config"
if command -v tmux &> /dev/null && [ -z "$TMUX" ]; then
    tmux new -A -s main
fi

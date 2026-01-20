# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH

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
plugins=(git)

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

# Task.dev - System-wide task runner
# Taskfile.dist.yml is located at ~/Taskfile.dist.yml
# Common tasks:
#   task gu             - Git update (fetch and pull)
#   task buildhiro      - Build Hiro plugin
#   task nwt BRANCH=X   - Create new worktree and build
#   task t              - Open tmux session
#   task docker-nuke    - Clean up Docker
#   task list-worktrees - List all worktrees
#   v2mp3 file.mov      - Convert video to mp3 audio
# Run 'task --list' to see all available tasks

# Convenience aliases for common tasks
alias gu='task gu'
alias buildhiro='task buildhiro'
alias docker-nuke='task docker-nuke'

# Wrapper functions for tasks that need parameters
nwt() {
    task nwt BRANCH="$1"
}

cwt() {
    task ewt BRANCH="$1"
}

v2mp3() {
    task video-to-mp3 -- "$1"
}

t() {
    task t
}

export VCPKG_ROOT=~/vcpkg
export PATH=$VCPKG_ROOT:$PATH
export PATH=$PATH:$HOME/go/bin

export KUBECONFIG=/Users/andres/Developer/devops/user_access_config/kube/config
export EGOS=$HOME/Developer/egos-2000
export PATH=$PATH:$HOME/Developer/xpack-riscv-none-elf-gcc-14.2.0-3/bin
# Created by `pipx` on 2026-01-13 12:52:31
export PATH="$PATH:/Users/andres/.local/bin"

# opencode
export PATH=/Users/andres/.opencode/bin:$PATH
export XDG_CONFIG_HOME="$HOME/.config"

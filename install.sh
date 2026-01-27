#!/bin/bash
#
# Bootstrap a new dev machine with a single command:
#   sh -c "$(curl -fsSL https://raw.githubusercontent.com/andresfelipemendez/dotfiles/main/install.sh)"
#

set -eo pipefail

# =============================================================================
# Configuration
# =============================================================================
DOTFILES_REPO="https://github.com/andresfelipemendez/dotfiles.git"
DOTFILES_DIR="$HOME/dotfiles"
OS="$(uname -s)"

# =============================================================================
# Helper functions
# =============================================================================
TEMP_DIR=""

info() {
    printf '\033[0;34m%s\033[0m\n' "$1"
}

error() {
    printf '\033[0;31m%s\033[0m\n' "$1" >&2
}

cleanup() {
    if [[ -n "$TEMP_DIR" && -d "$TEMP_DIR" ]]; then
        rm -rf "$TEMP_DIR"
    fi
}
trap cleanup EXIT

setup_temp() {
    TEMP_DIR=$(mktemp -d -t dotfiles-install.XXXXXX)
}

detect_os() {
    case "$OS" in
        Darwin)
            info "Detected: macOS"
            ;;
        Linux)
            if [[ ! -f /etc/debian_version ]]; then
                error "This script only supports Debian/Ubuntu-based systems on Linux"
                exit 1
            fi
            info "Detected: Debian/Ubuntu Linux"
            ;;
        *)
            error "Unsupported operating system: $OS"
            exit 1
            ;;
    esac
}

detect_arch() {
    ARCH=$(uname -m)
    case "$ARCH" in
        x86_64)
            ARCH_SUFFIX="amd64"
            ARCH_MUSL="x86_64-unknown-linux-musl"
            ARCH_LINUX="Linux_x86_64"
            ;;
        aarch64|arm64)
            ARCH_SUFFIX="arm64"
            ARCH_MUSL="aarch64-unknown-linux-musl"
            ARCH_LINUX="Linux_arm64"
            ;;
        *)
            error "Unsupported architecture: $ARCH"
            exit 1
            ;;
    esac
}

fetch_gpg_key() {
    local url="$1"
    local output="$2"
    local temp_key
    temp_key=$(mktemp -p "$TEMP_DIR" gpgkey.XXXXXX)

    if ! curl -fsSL "$url" -o "$temp_key"; then
        error "Failed to download GPG key from $url"
        return 1
    fi

    if [[ ! -s "$temp_key" ]]; then
        error "Downloaded GPG key is empty"
        return 1
    fi

    sudo gpg --batch --yes --dearmor -o "$output" < "$temp_key"
}

get_github_version() {
    local repo="$1"
    local version

    version=$(curl -fsSL "https://api.github.com/repos/${repo}/releases/latest" | grep -Po '"tag_name": "v?\K[^"]*' || true)

    if [[ -z "$version" ]]; then
        error "Failed to fetch latest version for $repo (GitHub API may be rate-limited)"
        return 1
    fi

    echo "$version"
}

get_kubectl_version() {
    local version
    version=$(curl -fsSL "https://dl.k8s.io/release/stable.txt" || true)

    if [[ -z "$version" || ! "$version" =~ ^v[0-9]+\.[0-9]+ ]]; then
        error "Failed to fetch latest kubectl version, defaulting to v1.31"
        echo "v1.31"
        return 0
    fi

    echo "$version" | grep -Po 'v[0-9]+\.[0-9]+'
}

check_and_install() {
    local package_name="$1"
    local install_function="$2"

    if command -v "$package_name" &>/dev/null; then
        info "$package_name is already installed"
    elif [[ "$OS" == "Linux" ]] && dpkg -s "$package_name" &>/dev/null; then
        info "$package_name is already installed"
    else
        info "$package_name not found, installing..."
        if [[ -n "$install_function" ]] && type "$install_function" &>/dev/null; then
            $install_function
        elif [[ "$OS" == "Darwin" ]]; then
            brew install "$package_name"
        else
            sudo apt-get install -y "$package_name"
        fi
    fi
}

check_and_install_cask() {
    local app_name="$1"
    local cask_name="$2"

    if [[ -d "/Applications/${app_name}.app" ]] || command -v "$cask_name" &>/dev/null; then
        info "$app_name is already installed"
    else
        info "$app_name not found, installing..."
        brew install --cask "$cask_name"
    fi
}

# =============================================================================
# Install functions (Linux-specific)
# =============================================================================
install_1password_linux() {
    info "Installing 1Password (Desktop + CLI)..."

    fetch_gpg_key "https://downloads.1password.com/linux/keys/1password.asc" \
        "/usr/share/keyrings/1password-archive-keyring.gpg"

    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/$(dpkg --print-architecture) stable main" | \
        sudo tee /etc/apt/sources.list.d/1password.list >/dev/null

    sudo mkdir -p /etc/debsig/policies/AC2D62742012EA22/
    curl -fsSL https://downloads.1password.com/linux/debian/debsig/1password.pol | \
        sudo tee /etc/debsig/policies/AC2D62742012EA22/1password.pol >/dev/null

    sudo mkdir -p /usr/share/debsig/keyrings/AC2D62742012EA22
    fetch_gpg_key "https://downloads.1password.com/linux/keys/1password.asc" \
        "/usr/share/debsig/keyrings/AC2D62742012EA22/debsig.gpg"

    sudo apt-get update
    sudo apt-get install -y 1password 1password-cli
}

install_lazygit_linux() {
    info "Installing lazygit..."
    local version
    version=$(get_github_version "jesseduffield/lazygit") || return 1
    curl -fsSL -o "$TEMP_DIR/lazygit.tar.gz" "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${version}_${ARCH_LINUX}.tar.gz"
    tar xf "$TEMP_DIR/lazygit.tar.gz" -C "$TEMP_DIR" lazygit
    sudo install "$TEMP_DIR/lazygit" /usr/local/bin
}

install_fd_linux() {
    info "Installing fd-find..."
    local version
    version=$(get_github_version "sharkdp/fd") || return 1
    curl -fsSL -o "$TEMP_DIR/fd.tar.gz" "https://github.com/sharkdp/fd/releases/latest/download/fd-v${version}-${ARCH_MUSL}.tar.gz"
    tar xf "$TEMP_DIR/fd.tar.gz" -C "$TEMP_DIR" "fd-v${version}-${ARCH_MUSL}/fd"
    sudo install "$TEMP_DIR/fd-v${version}-${ARCH_MUSL}/fd" /usr/local/bin/fd
}

install_bat_linux() {
    info "Installing bat..."
    local version
    version=$(get_github_version "sharkdp/bat") || return 1
    curl -fsSL -o "$TEMP_DIR/bat.tar.gz" "https://github.com/sharkdp/bat/releases/latest/download/bat-v${version}-${ARCH_MUSL}.tar.gz"
    tar xf "$TEMP_DIR/bat.tar.gz" -C "$TEMP_DIR" "bat-v${version}-${ARCH_MUSL}/bat"
    sudo install "$TEMP_DIR/bat-v${version}-${ARCH_MUSL}/bat" /usr/local/bin/bat
}

install_fzf_linux() {
    info "Installing fzf..."
    local version
    version=$(get_github_version "junegunn/fzf") || return 1
    curl -fsSL -o "$TEMP_DIR/fzf.tar.gz" "https://github.com/junegunn/fzf/releases/download/v${version}/fzf-${version}-linux_${ARCH_SUFFIX}.tar.gz"
    tar xf "$TEMP_DIR/fzf.tar.gz" -C "$TEMP_DIR" fzf
    sudo install "$TEMP_DIR/fzf" /usr/local/bin/fzf
}

install_gcloud_linux() {
    info "Installing Google Cloud SDK..."
    fetch_gpg_key "https://packages.cloud.google.com/apt/doc/apt-key.gpg" \
        "/usr/share/keyrings/cloud.google.gpg"
    echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | \
        sudo tee /etc/apt/sources.list.d/google-cloud-sdk.list >/dev/null
    sudo apt-get update
    sudo apt-get install -y google-cloud-cli
}

install_kubectl_linux() {
    info "Installing kubectl..."
    local k8s_version
    k8s_version=$(get_kubectl_version)
    info "Using Kubernetes version: $k8s_version"

    fetch_gpg_key "https://pkgs.k8s.io/core:/stable:/${k8s_version}/deb/Release.key" \
        "/usr/share/keyrings/kubernetes-apt-keyring.gpg"
    echo "deb [signed-by=/usr/share/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/${k8s_version}/deb/ /" | \
        sudo tee /etc/apt/sources.list.d/kubernetes.list >/dev/null
    sudo apt-get update
    sudo apt-get install -y kubectl
}

install_gh_linux() {
    info "Installing GitHub CLI..."
    fetch_gpg_key "https://cli.github.com/packages/githubcli-archive-keyring.gpg" \
        "/usr/share/keyrings/githubcli-archive-keyring.gpg"
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | \
        sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
    sudo apt-get update
    sudo apt-get install -y gh
}

install_docker_linux() {
    info "Installing Docker..."

    # Install prerequisites
    sudo apt-get install -y ca-certificates gnupg

    # Add Docker's official GPG key
    sudo install -m 0755 -d /etc/apt/keyrings
    fetch_gpg_key "https://download.docker.com/linux/ubuntu/gpg" \
        "/etc/apt/keyrings/docker.gpg"
    sudo chmod a+r /etc/apt/keyrings/docker.gpg

    # Add Docker repository
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
        sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

    # Install Docker
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    # Add current user to docker group (no sudo needed for docker commands)
    sudo groupadd -f docker
    sudo usermod -aG docker "$USER"

    info "Docker installed. Log out and back in for group changes to take effect."
}

# =============================================================================
# Cross-platform install functions
# =============================================================================
install_ohmyzsh() {
    if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
        info "Installing Oh My Zsh..."
        RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    else
        info "Oh My Zsh is already installed"
    fi
}

install_zsh_plugins() {
    local ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

    info "Installing zsh plugins..."

    if [[ ! -d "$ZSH_CUSTOM/plugins/you-should-use" ]]; then
        info "Installing zsh-you-should-use..."
        git clone https://github.com/MichaelAquilina/zsh-you-should-use.git "$ZSH_CUSTOM/plugins/you-should-use"
    else
        info "zsh-you-should-use already installed"
    fi

    if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-bat" ]]; then
        info "Installing zsh-bat..."
        git clone https://github.com/fdellwing/zsh-bat.git "$ZSH_CUSTOM/plugins/zsh-bat"
    else
        info "zsh-bat already installed"
    fi

    if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]]; then
        info "Installing zsh-syntax-highlighting..."
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
    else
        info "zsh-syntax-highlighting already installed"
    fi

    if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]]; then
        info "Installing zsh-autosuggestions..."
        git clone https://github.com/zsh-users/zsh-autosuggestions.git "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
    else
        info "zsh-autosuggestions already installed"
    fi
}

install_homebrew() {
    if ! command -v brew &>/dev/null; then
        info "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

        # Add brew to PATH for this session
        if [[ -f "/opt/homebrew/bin/brew" ]]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        elif [[ -f "/usr/local/bin/brew" ]]; then
            eval "$(/usr/local/bin/brew shellenv)"
        fi
    else
        info "Homebrew is already installed"
    fi
}

# =============================================================================
# Main
# =============================================================================
main() {
    info "=========================================="
    info "  Dotfiles Bootstrap"
    info "=========================================="

    # Validate OS and detect architecture
    detect_os
    detect_arch

    # Setup temp directory
    setup_temp

    if [[ "$OS" == "Darwin" ]]; then
        # macOS setup
        install_homebrew

        # Install git and curl (usually pre-installed on macOS)
        check_and_install "git" ""
        check_and_install "curl" ""

        # Clone dotfiles
        if [[ ! -d "$DOTFILES_DIR" ]]; then
            info "Cloning dotfiles..."
            git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
        else
            info "Dotfiles already cloned, pulling latest..."
            git -C "$DOTFILES_DIR" pull --ff-only || true
        fi

        cd "$DOTFILES_DIR"
        chmod +x install.sh symlink.sh

        # Install core packages via brew
        info "Installing core packages..."
        check_and_install "zsh" ""
        check_and_install "tmux" ""
        check_and_install "neovim" ""
        check_and_install "htop" ""
        check_and_install "ripgrep" ""
        check_and_install "fzf" ""
        check_and_install "lazygit" ""
        check_and_install "fd" ""
        check_and_install "bat" ""
        check_and_install "gh" ""
        check_and_install "kubectl" ""

        # Install cask applications
        info "Installing applications..."
        check_and_install_cask "1Password" "1password"
        check_and_install_cask "Docker" "docker"
        check_and_install_cask "Hammerspoon" "hammerspoon"
        check_and_install_cask "Ghostty" "ghostty"

        # Google Cloud SDK
        if ! command -v gcloud &>/dev/null; then
            info "Installing Google Cloud SDK..."
            brew install --cask google-cloud-sdk
        else
            info "gcloud is already installed"
        fi

    else
        # Linux setup
        info "Installing bootstrap packages..."
        sudo apt-get update
        sudo apt-get install -y git curl

        # Clone dotfiles
        if [[ ! -d "$DOTFILES_DIR" ]]; then
            info "Cloning dotfiles..."
            git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
        else
            info "Dotfiles already cloned, pulling latest..."
            git -C "$DOTFILES_DIR" pull --ff-only || true
        fi

        cd "$DOTFILES_DIR"
        chmod +x install.sh symlink.sh

        # Install core packages
        info "Installing core packages..."
        packages="zsh tmux neovim xclip htop unzip"

        if apt-cache show ripgrep &>/dev/null; then
            packages="$packages ripgrep"
        fi

        for package in $packages; do
            check_and_install "$package" ""
        done

        # Install tools from GitHub (latest versions)
        info "Installing tools from GitHub..."
        check_and_install "fzf" "install_fzf_linux"
        check_and_install "lazygit" "install_lazygit_linux"
        check_and_install "fd" "install_fd_linux"
        check_and_install "bat" "install_bat_linux"

        # Install from official repos
        info "Installing from official repos..."
        check_and_install "gh" "install_gh_linux"
        check_and_install "docker" "install_docker_linux"
        check_and_install "1password" "install_1password_linux"
        check_and_install "gcloud" "install_gcloud_linux"
        check_and_install "kubectl" "install_kubectl_linux"
    fi

    # Install Oh My Zsh (cross-platform)
    install_ohmyzsh

    # Install zsh plugins (cross-platform)
    install_zsh_plugins

    # Create symlinks
    info "Creating symlinks..."
    ./symlink.sh

    info "=========================================="
    info "  Installation complete!"
    info "=========================================="
    info ""
    info "Next steps:"
    if [[ "$OS" == "Darwin" ]]; then
        info "  1. chsh -s /bin/zsh         # Set zsh as default shell (if not already)"
        info "  2. Restart your terminal"
    else
        info "  1. chsh -s \$(which zsh)   # Set zsh as default shell"
        info "  2. Log out and back in     # Required for zsh + docker group"
    fi
    info ""
}

main "$@"

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
    if [[ ! -f /etc/debian_version ]]; then
        error "This script only supports Debian/Ubuntu-based systems"
        exit 1
    fi
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
    elif dpkg -s "$package_name" &>/dev/null; then
        info "$package_name is already installed"
    else
        info "$package_name not found, installing..."
        if [[ -n "$install_function" ]] && type "$install_function" &>/dev/null; then
            $install_function
        else
            sudo apt-get install -y "$package_name"
        fi
    fi
}

# =============================================================================
# Install functions
# =============================================================================
install_1password() {
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

install_lazygit() {
    info "Installing lazygit..."
    local version
    version=$(get_github_version "jesseduffield/lazygit") || return 1
    curl -fsSL -o "$TEMP_DIR/lazygit.tar.gz" "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${version}_${ARCH_LINUX}.tar.gz"
    tar xf "$TEMP_DIR/lazygit.tar.gz" -C "$TEMP_DIR" lazygit
    sudo install "$TEMP_DIR/lazygit" /usr/local/bin
}

install_fd() {
    info "Installing fd-find..."
    local version
    version=$(get_github_version "sharkdp/fd") || return 1
    curl -fsSL -o "$TEMP_DIR/fd.tar.gz" "https://github.com/sharkdp/fd/releases/latest/download/fd-v${version}-${ARCH_MUSL}.tar.gz"
    tar xf "$TEMP_DIR/fd.tar.gz" -C "$TEMP_DIR" "fd-v${version}-${ARCH_MUSL}/fd"
    sudo install "$TEMP_DIR/fd-v${version}-${ARCH_MUSL}/fd" /usr/local/bin/fd
}

install_bat() {
    info "Installing bat..."
    local version
    version=$(get_github_version "sharkdp/bat") || return 1
    curl -fsSL -o "$TEMP_DIR/bat.tar.gz" "https://github.com/sharkdp/bat/releases/latest/download/bat-v${version}-${ARCH_MUSL}.tar.gz"
    tar xf "$TEMP_DIR/bat.tar.gz" -C "$TEMP_DIR" "bat-v${version}-${ARCH_MUSL}/bat"
    sudo install "$TEMP_DIR/bat-v${version}-${ARCH_MUSL}/bat" /usr/local/bin/bat
}

install_fzf() {
    info "Installing fzf..."
    local version
    version=$(get_github_version "junegunn/fzf") || return 1
    curl -fsSL -o "$TEMP_DIR/fzf.tar.gz" "https://github.com/junegunn/fzf/releases/download/v${version}/fzf-${version}-linux_${ARCH_SUFFIX}.tar.gz"
    tar xf "$TEMP_DIR/fzf.tar.gz" -C "$TEMP_DIR" fzf
    sudo install "$TEMP_DIR/fzf" /usr/local/bin/fzf
}

install_gcloud() {
    info "Installing Google Cloud SDK..."
    fetch_gpg_key "https://packages.cloud.google.com/apt/doc/apt-key.gpg" \
        "/usr/share/keyrings/cloud.google.gpg"
    echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | \
        sudo tee /etc/apt/sources.list.d/google-cloud-sdk.list >/dev/null
    sudo apt-get update
    sudo apt-get install -y google-cloud-cli
}

install_kubectl() {
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

install_docker() {
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

install_ohmyzsh() {
    if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
        info "Installing Oh My Zsh..."
        RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    else
        info "Oh My Zsh is already installed"
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
    info "Detected: Debian/Ubuntu on $ARCH"

    # Setup temp directory
    setup_temp

    # Install bootstrap packages first (needed before we can clone)
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
    check_and_install "fzf" "install_fzf"
    check_and_install "lazygit" "install_lazygit"
    check_and_install "fd" "install_fd"
    check_and_install "bat" "install_bat"

    # Install from official repos
    info "Installing from official repos..."
    check_and_install "docker" "install_docker"
    check_and_install "1password" "install_1password"
    check_and_install "gcloud" "install_gcloud"
    check_and_install "kubectl" "install_kubectl"

    # Install Oh My Zsh
    install_ohmyzsh

    # Create symlinks
    info "Creating symlinks..."
    ./symlink.sh

    info "=========================================="
    info "  Installation complete!"
    info "=========================================="
    info ""
    info "Next steps:"
    info "  1. chsh -s \$(which zsh)   # Set zsh as default shell"
    info "  2. Log out and back in     # Required for zsh + docker group"
    info ""
}

main "$@"

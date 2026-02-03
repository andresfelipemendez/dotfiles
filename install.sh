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

# Compare two semantic versions, returns 0 if $1 > $2
version_gt() {
    local v1="$1" v2="$2"
    # Strip leading 'v' if present
    v1="${v1#v}"
    v2="${v2#v}"
    # Use sort -V to compare versions
    [[ "$(printf '%s\n%s' "$v1" "$v2" | sort -V | tail -1)" != "$v2" ]]
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

install_gcloud_linux() {
    info "Installing Google Cloud SDK..."
    fetch_gpg_key "https://packages.cloud.google.com/apt/doc/apt-key.gpg" \
        "/usr/share/keyrings/cloud.google.gpg"
    echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | \
        sudo tee /etc/apt/sources.list.d/google-cloud-sdk.list >/dev/null
    sudo apt-get update
    sudo apt-get install -y google-cloud-cli
}

install_nix() {
    if command -v nix &>/dev/null; then
        info "Nix is already installed"
    else
        info "Installing Nix package manager..."
        sh <(curl -L https://nixos.org/nix/install) --daemon --yes

        # Source nix for current session
        if [[ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]]; then
            . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
        fi
    fi

    # Enable experimental features (required for nix profile commands)
    local nix_conf_dir="/etc/nix"
    local nix_conf="$nix_conf_dir/nix.conf"
    if ! grep -q "experimental-features" "$nix_conf" 2>/dev/null; then
        info "Enabling Nix experimental features..."
        echo "experimental-features = nix-command flakes" | sudo tee -a "$nix_conf" >/dev/null
    fi
}

install_nix_packages() {
    info "Installing packages via Nix..."

    # Ensure nix is installed
    install_nix

    # Source nix if not already in path
    if ! command -v nix &>/dev/null; then
        if [[ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]]; then
            . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
        fi
    fi

    # Install packages via nix profile
    local nix_packages=(
        "fzf"
        "lazygit"
        "fd"
        "bat"
        "gh"
        "kubectl"
        "ripgrep"
        "ghostty"
    )

    for pkg in "${nix_packages[@]}"; do
        if command -v "$pkg" &>/dev/null; then
            info "$pkg is already installed"
        else
            info "Installing $pkg via Nix..."
            nix profile add "nixpkgs#$pkg"
        fi
    done
}

install_neovim_nix() {
    info "Checking neovim version..."

    # Ensure nix is available
    if ! command -v nix &>/dev/null; then
        if [[ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]]; then
            . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
        fi
    fi

    # Get available version from nixpkgs
    local nix_version
    nix_version=$(nix eval --raw nixpkgs#neovim.version 2>/dev/null || echo "")
    if [[ -z "$nix_version" ]]; then
        error "Failed to get neovim version from nixpkgs"
        return 1
    fi

    # Get current installed version (if any)
    local current_version=""
    if command -v nvim &>/dev/null; then
        current_version=$(nvim --version | head -1 | grep -oP 'v?\K[0-9]+\.[0-9]+\.[0-9]+' || echo "")
    fi

    if [[ -z "$current_version" ]]; then
        info "neovim not installed, installing v$nix_version via Nix..."
        nix profile add nixpkgs#neovim
    elif version_gt "$nix_version" "$current_version"; then
        info "neovim upgrade available: v$current_version -> v$nix_version"
        info "Installing neovim v$nix_version via Nix..."
        nix profile add nixpkgs#neovim
    else
        info "neovim v$current_version is up to date (nixpkgs has v$nix_version)"
    fi
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

    # Validate OS
    detect_os

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

        # Install core packages via apt
        info "Installing core packages via apt..."
        packages="zsh tmux xclip htop unzip"
        for package in $packages; do
            check_and_install "$package" ""
        done

        # Install packages via Nix (fzf, lazygit, fd, bat, gh, kubectl, ripgrep, ghostty)
        install_nix_packages

        # Install neovim via Nix (with version check)
        install_neovim_nix

        # Install from official repos (these need special setup)
        info "Installing from official repos..."
        check_and_install "docker" "install_docker_linux"
        check_and_install "1password" "install_1password_linux"
        check_and_install "gcloud" "install_gcloud_linux"
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

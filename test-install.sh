#!/bin/bash
#
# Test install.sh in a fresh Ubuntu container
#
# Usage: ./test-install.sh
#

set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== Testing install.sh in fresh Ubuntu 24.04 container ==="
echo ""

docker run --rm -it \
    -v "$SCRIPT_DIR":/dotfiles:ro \
    ubuntu:24.04 \
    bash -c '
set -e

echo "[1/3] Setting up test environment..."
apt-get update -qq
apt-get install -y -qq sudo >/dev/null

# Create test user with passwordless sudo
useradd -m -s /bin/bash testuser
echo "testuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

echo "[2/3] Running install.sh as testuser..."
echo ""
su - testuser -c "bash /dotfiles/install.sh"

echo ""
echo "[3/3] Verifying installations..."
su - testuser -c "
    echo \"Checking installed tools:\"
    for cmd in git zsh fzf lazygit fd bat gh docker gcloud kubectl 1password; do
        if command -v \$cmd &>/dev/null; then
            printf \"  %-12s ✓\\n\" \$cmd
        else
            printf \"  %-12s ✗ MISSING\\n\" \$cmd
        fi
    done
    echo \"\"
    echo \"Checking symlinks:\"
    for f in ~/.zshrc ~/.gitconfig ~/.config/lazygit; do
        if [ -L \"\$f\" ]; then
            printf \"  %-25s ✓ -> %s\\n\" \$f \$(readlink \$f)
        else
            printf \"  %-25s ✗ NOT LINKED\\n\" \$f
        fi
    done
"
'

echo ""
echo "=== Test complete ==="

#!/bin/bash
echo "[*] Installing yay AUR helper..."

# Install yay if not already present
if ! command -v yay &> /dev/null; then
    # Create temporary build user if needed
    if ! id "builduser" &> /dev/null; then
        useradd -m builduser
        echo "builduser ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
    fi
    
    # Install base-devel if not present
    pacman -S --needed --noconfirm base-devel git
    
    # Clone and build yay
    sudo -u builduser git clone https://aur.archlinux.org/yay.git /tmp/yay
    cd /tmp/yay
    sudo -u builduser makepkg -si --noconfirm
    cd /
    rm -rf /tmp/yay
fi

echo "[*] Installing extras..."
yay -S --noconfirm zmap rustscan gping ungoogled-chromium python311 || true

echo "[*] Installing Nix tools..."
nix-env -iA nixpkgs.amass nixpkgs.nuclei || true

echo "[*] Done"

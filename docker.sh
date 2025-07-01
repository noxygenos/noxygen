#!/bin/bash
set -euxo pipefail

# Aggressive cleanup to avoid file conflicts
chmod -R 777 work/ out/ airootfs/ build/ cache/ 2>/dev/null || true
rm -rf work/ out/ airootfs/ build/ cache/
# Clean any potential leftover files in the build directory
find . -name "*.pkg.tar*" -delete 2>/dev/null || true
find . -name "*.log" -delete 2>/dev/null || true
# Clean potential archiso state
rm -rf /tmp/archiso* 2>/dev/null || true
# Clean pacman cache completely
rm -rf /var/cache/pacman/pkg/* 2>/dev/null || true

# Update system and install essentials for building
pacman -Sy --noconfirm archiso base-devel sudo git curl wget go

# Ensure archiso hooks are available
if [ ! -d "/usr/lib/initcpio/hooks" ]; then
    mkdir -p /usr/lib/initcpio/hooks
fi
if [ ! -d "/usr/lib/initcpio/install" ]; then
    mkdir -p /usr/lib/initcpio/install
fi

# Verify archiso installation and hooks
pacman -Qi archiso || pacman -S --noconfirm archiso
echo "=== Checking for archiso hooks ==="
ls -la /usr/lib/initcpio/hooks/archiso* 2>/dev/null || echo "Warning: archiso hooks not found"
ls -la /usr/lib/initcpio/install/archiso* 2>/dev/null || echo "Warning: archiso install hooks not found"
echo "=== End archiso hook check ==="

# Initialize pacman keyring fresh to avoid any key conflicts
pacman-key --init
pacman-key --populate archlinux

# Ensure we have a completely fresh releng profile
rm -rf releng/ 2>/dev/null || true
# Copy releng profile for custom ISO
cp -r /usr/share/archiso/configs/releng/* .

# Copy configuration files
cp configs/packages.x86_64 .
cp configs/hostname airootfs/etc/hostname

# Set root password
ROOT_PASS_HASH=$(openssl passwd -6 "root")
sed -i "s|^root:[^:]*:|root:$ROOT_PASS_HASH:|" airootfs/etc/shadow

# Enable autologin + Sway
mkdir -p airootfs/root
cp configs/xinitrc airootfs/root/.xinitrc
cp configs/bash_profile airootfs/root/.bash_profile

mkdir -p airootfs/etc/systemd/system/getty@tty1.service.d
cp configs/autologin.conf airootfs/etc/systemd/system/getty@tty1.service.d/

# Set Sway wallpaper
mkdir -p airootfs/usr/share/backgrounds
cp configs/backdrop.png airootfs/usr/share/backgrounds/backdrop.png

# Sway configuration
mkdir -p airootfs/root/.config/sway
cp configs/sway-config airootfs/root/.config/sway/config

# MOTD and Neofetch
mkdir -p airootfs/etc/profile.d
cp configs/neofetch.sh airootfs/etc/profile.d/
chmod +x airootfs/etc/profile.d/neofetch.sh

# MITM Autostart
cp configs/mitm.sh airootfs/etc/profile.d/
chmod +x airootfs/etc/profile.d/mitm.sh

# Multi-Package Installer including ungoogled-chromium and python311 build from AUR
cp configs/install.sh airootfs/etc/profile.d/
chmod +x airootfs/etc/profile.d/install.sh

# Modern tool aliases
cp configs/aliases.sh airootfs/etc/profile.d/
chmod +x airootfs/etc/profile.d/aliases.sh

# Wordlists setup
cp configs/setup-wordlists.sh airootfs/etc/profile.d/
chmod +x airootfs/etc/profile.d/setup-wordlists.sh

# Python packages setup
cp configs/setup-python.sh airootfs/etc/profile.d/
chmod +x airootfs/etc/profile.d/setup-python.sh

# Desktop and user setup
cp configs/desktop.sh airootfs/etc/profile.d/
chmod +x airootfs/etc/profile.d/desktop.sh


# Build the ISO with explicit clean directories
mkdir -p ./work ./out
mkarchiso -v -w ./work -o ./out .

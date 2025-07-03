#!/bin/bash
set -euxo pipefail

# Noxygen Ubuntu/Debian ISO Builder
# This script builds a custom Ubuntu/Debian-based penetration testing live ISO

DISTRO_NAME="NoxygenOS"
BUILD_DIR="./build"
ISO_OUTPUT_DIR="./iso"
WORK_DIR="$BUILD_DIR/work"
CHROOT_DIR="$WORK_DIR/chroot"

# Fast build mode - set environment variables to skip time-consuming steps
# FAST_BUILD=1 ./ubuntu-setup.sh
if [ "${FAST_BUILD:-0}" == "1" ]; then
    echo "[*] Fast build mode enabled - skipping wordlists and some tools"
    export SKIP_WORDLISTS=1
    export SKIP_HEAVY_TOOLS=1
fi

echo "[*] Starting Noxygen ISO build for Ubuntu/Debian..."

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root (sudo ./ubuntu-setup.sh)"
    exit 1
fi

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$NAME
    VER=$VERSION_ID
else
    echo "Cannot detect OS. This script is for Ubuntu/Debian systems."
    exit 1
fi

echo "[*] Detected OS: $OS $VER"

# Ensure we're on Ubuntu/Debian
if [[ ! "$OS" =~ "Ubuntu" ]] && [[ ! "$OS" =~ "Debian" ]]; then
    echo "This script is designed for Ubuntu or Debian systems only."
    exit 1
fi

# Install ISO building tools
echo "[*] Installing ISO building tools..."
apt install -y \
    debootstrap \
    squashfs-tools \
    xorriso \
    isolinux \
    syslinux-efi \
    grub-pc-bin \
    grub-efi-amd64-bin \
    mtools

# Determine Ubuntu/Debian codename for debootstrap
if [[ "$OS" =~ "Ubuntu" ]]; then
    if [[ "$VER" == "22.04" ]]; then
        CODENAME="jammy"
    elif [[ "$VER" == "20.04" ]]; then
        CODENAME="focal"
    elif [[ "$VER" == "24.04" ]]; then
        CODENAME="noble"
    else
        CODENAME="jammy"  # Default to LTS
    fi
    MIRROR="http://us.archive.ubuntu.com/ubuntu"
else
    # Debian
    if [[ "$VER" == "11" ]]; then
        CODENAME="bullseye"
    elif [[ "$VER" == "12" ]]; then
        CODENAME="bookworm"
    else
        CODENAME="bookworm"  # Default to stable
    fi
    MIRROR="http://deb.debian.org/debian"
fi

echo "[*] Using codename: $CODENAME"

# Clean up previous builds
echo "[*] Cleaning up previous builds..."
# Unmount any mounted filesystems from a previous run
for mp in dev/pts dev proc sys; do
    if mountpoint -q "$BUILD_DIR/work/chroot/$mp"; then
        echo "[*] Unmounting leftover $mp"
        umount -l "$BUILD_DIR/work/chroot/$mp" || true
    fi
 done
sudo rm -rf "$BUILD_DIR" "$ISO_OUTPUT_DIR"
mkdir -p "$WORK_DIR" "$ISO_OUTPUT_DIR" "$CHROOT_DIR"

# Create base system with debootstrap
echo "[*] Creating base system with debootstrap..."
debootstrap --arch=amd64 --variant=minbase "$CODENAME" "$CHROOT_DIR" "$MIRROR"

# Configure APT sources in chroot
echo "[*] Configuring APT sources..."
cat > "$CHROOT_DIR/etc/apt/sources.list" << EOF
deb $MIRROR $CODENAME main restricted universe multiverse
deb $MIRROR $CODENAME-updates main restricted universe multiverse
deb $MIRROR $CODENAME-security main restricted universe multiverse
EOF

# Function to run commands in chroot
chroot_exec() {
    chroot "$CHROOT_DIR" /bin/bash -c "$*"
}

# Mount necessary filesystems for chroot
echo "[*] Setting up chroot environment..."
mount --bind /dev "$CHROOT_DIR/dev"
mount --bind /dev/pts "$CHROOT_DIR/dev/pts"
mount --bind /proc "$CHROOT_DIR/proc"
mount --bind /sys "$CHROOT_DIR/sys"

# Optimize APT for parallel downloads in chroot
echo "[*] Optimizing APT for faster downloads..."
chroot_exec "echo 'Acquire::Queue-Mode \"access\";' > /etc/apt/apt.conf.d/00-parallel-downloads"
chroot_exec "echo 'APT::Acquire::Retries \"3\";' >> /etc/apt/apt.conf.d/00-parallel-downloads"
chroot_exec "echo 'Acquire::http::Pipeline-Depth \"5\";' >> /etc/apt/apt.conf.d/00-parallel-downloads"

# Update package lists with retry logic
echo "[*] Updating package lists in chroot..."
for i in {1..3}; do
    echo "Attempt $i/3 to update package lists..."
    if chroot_exec "apt update"; then
        break
    else
        echo "Update failed, waiting 10 seconds before retry..."
        sleep 10
        if [ $i -eq 3 ]; then
            echo "Using --allow-releaseinfo-change to handle repository issues..."
            chroot_exec "apt update --allow-releaseinfo-change" || true
        fi
    fi
done

# Install essential packages in chroot with optimized retry logic
echo "[*] Installing essential packages in chroot..."
chroot_exec "apt update --fix-missing"
for i in {1..2}; do
    echo "Attempt $i/2 to install essential packages..."
    if chroot_exec "DEBIAN_FRONTEND=noninteractive apt install -y --no-install-recommends \
        linux-image-generic \
        linux-headers-generic \
        live-boot \
        systemd-sysv \
        locales \
        keyboard-configuration \
        console-setup \
        sudo \
        network-manager \
        openssh-server \
        curl \
        wget \
        git \
        vim \
        nano"; then
        break
    else
        echo "Installation failed, retrying..."
        chroot_exec "apt clean && apt update"
        sleep 5
    fi
done

# Copy our custom configurations into chroot
echo "[*] Copying custom configurations..."

# Set hostname
if [ -f configs/hostname ]; then
    cp configs/hostname "$CHROOT_DIR/etc/hostname"
fi

# Copy shell configurations
mkdir -p "$CHROOT_DIR/root"
if [ -f configs/xinitrc ]; then
    cp configs/xinitrc "$CHROOT_DIR/root/.xinitrc"
fi
if [ -f configs/bash_profile ]; then
    cp configs/bash_profile "$CHROOT_DIR/root/.bash_profile"
fi

# Set up Sway configuration
mkdir -p "$CHROOT_DIR/root/.config/sway"
if [ -f configs/sway-config ]; then
    cp configs/sway-config "$CHROOT_DIR/root/.config/sway/config"
fi

# Set wallpaper
mkdir -p "$CHROOT_DIR/usr/share/backgrounds"
if [ -f configs/backdrop.png ]; then
    cp configs/backdrop.png "$CHROOT_DIR/usr/share/backgrounds/backdrop.png"
fi

# Set up profile scripts
mkdir -p "$CHROOT_DIR/etc/profile.d"
for script in configs/neofetch.sh configs/aliases.sh; do
    if [ -f "$script" ]; then
        cp "$script" "$CHROOT_DIR/etc/profile.d/"
        chmod +x "$CHROOT_DIR/etc/profile.d/$(basename $script)"
    fi
done

# Copy and run installation scripts in chroot
echo "[*] Installing penetration testing tools in chroot..."
cp -r configs "$CHROOT_DIR/tmp/"

# Install packages from our custom lists
if [ -f configs/packages-debian.txt ]; then
    echo "[*] Installing packages from packages-debian.txt..."
    chroot_exec "DEBIAN_FRONTEND=noninteractive apt install -y $(grep -v '^#' /tmp/configs/packages-debian.txt | tr '\n' ' ')"
fi

# Run custom install script
if [ -f configs/install.sh ]; then
    chmod +x "$CHROOT_DIR/tmp/configs/install.sh"
    chroot_exec "cd /tmp/configs && ./install.sh"
fi

# Set up Python environment
if [ -f configs/setup-python.sh ]; then
    chmod +x "$CHROOT_DIR/tmp/configs/setup-python.sh"
    chroot_exec "cd /tmp/configs && ./setup-python.sh"
fi

# Set up wordlists (skip if SKIP_WORDLISTS=1)
if [ -f configs/setup-wordlists.sh ] && [ "${SKIP_WORDLISTS:-0}" != "1" ]; then
    echo "[*] Setting up wordlists (set SKIP_WORDLISTS=1 to skip)..."
    chmod +x "$CHROOT_DIR/tmp/configs/setup-wordlists.sh"
    chroot_exec "cd /tmp/configs && ./setup-wordlists.sh"
else
    echo "[*] Skipping wordlists setup..."
fi

# Set up desktop environment
if [ -f configs/desktop.sh ]; then
    chmod +x "$CHROOT_DIR/tmp/configs/desktop.sh"
    chroot_exec "cd /tmp/configs && ./desktop.sh"
fi

# Configure autologin
mkdir -p "$CHROOT_DIR/etc/systemd/system/getty@tty1.service.d"
if [ -f configs/autologin.conf ]; then
    cp configs/autologin.conf "$CHROOT_DIR/etc/systemd/system/getty@tty1.service.d/"
    chroot_exec "systemctl enable getty@tty1.service"
fi

# Set up MITM tools
if [ -f configs/mitm.sh ]; then
    cp configs/mitm.sh "$CHROOT_DIR/etc/profile.d/"
    chmod +x "$CHROOT_DIR/etc/profile.d/mitm.sh"
fi

# Set root password
echo "[*] Setting root password..."
chroot_exec "echo 'root:root' | chpasswd"

# Configure locale
echo "[*] Configuring locale..."
chroot_exec "locale-gen en_US.UTF-8"
chroot_exec "update-locale LANG=en_US.UTF-8"

# Clean up chroot
echo "[*] Cleaning up chroot..."
chroot_exec "apt clean"
chroot_exec "rm -rf /tmp/configs"

# Unmount filesystems
echo "[*] Unmounting filesystems..."
umount "$CHROOT_DIR/sys" || true
umount "$CHROOT_DIR/proc" || true
umount "$CHROOT_DIR/dev/pts" || true
umount "$CHROOT_DIR/dev" || true

# Create squashfs filesystem
echo "[*] Creating squashfs filesystem..."
mkdir -p "$WORK_DIR/image/live"
mksquashfs "$CHROOT_DIR" "$WORK_DIR/image/live/filesystem.squashfs" -e boot

# Copy kernel and initrd
echo "[*] Copying kernel and initrd..."
cp "$CHROOT_DIR"/boot/vmlinuz-* "$WORK_DIR/image/live/vmlinuz"
cp "$CHROOT_DIR"/boot/initrd.img-* "$WORK_DIR/image/live/initrd"

# Create GRUB configuration
echo "[*] Creating GRUB configuration..."
mkdir -p "$WORK_DIR/image/boot/grub"
cat > "$WORK_DIR/image/boot/grub/grub.cfg" << EOF
set timeout=30
set default=0

menuentry "NoxygenOS Live" {
    linux /live/vmlinuz boot=live components quiet splash
    initrd /live/initrd
}

menuentry "NoxygenOS Live (Debug Mode)" {
    linux /live/vmlinuz boot=live components debug=1
    initrd /live/initrd
}

menuentry "NoxygenOS Live (Safe Mode)" {
    linux /live/vmlinuz boot=live components nosplash noapic noapm nodma nomce nolapic nomodeset
    initrd /live/initrd
}
EOF

# Create isolinux configuration for legacy boot
echo "[*] Creating isolinux configuration..."
mkdir -p "$WORK_DIR/image/isolinux"
cp /usr/lib/ISOLINUX/isolinux.bin "$WORK_DIR/image/isolinux/"
cp /usr/lib/syslinux/modules/bios/ldlinux.c32 "$WORK_DIR/image/isolinux/"
cp /usr/lib/syslinux/modules/bios/libcom32.c32 "$WORK_DIR/image/isolinux/"
cp /usr/lib/syslinux/modules/bios/libutil.c32 "$WORK_DIR/image/isolinux/"
cp /usr/lib/syslinux/modules/bios/vesamenu.c32 "$WORK_DIR/image/isolinux/"

cat > "$WORK_DIR/image/isolinux/isolinux.cfg" << EOF
DEFAULT vesamenu.c32
TIMEOUT 300
MENU TITLE NoxygenOS Live Boot Menu

LABEL live
    MENU LABEL NoxygenOS Live
    KERNEL /live/vmlinuz
    APPEND initrd=/live/initrd boot=live components quiet splash

LABEL debug
    MENU LABEL NoxygenOS Live (Debug Mode)
    KERNEL /live/vmlinuz
    APPEND initrd=/live/initrd boot=live components debug=1

LABEL safe
    MENU LABEL NoxygenOS Live (Safe Mode)
    KERNEL /live/vmlinuz
    APPEND initrd=/live/initrd boot=live components nosplash noapic noapm nodma nomce nolapic nomodeset
EOF

# Create ISO
echo "[*] Creating ISO image..."
xorriso -as mkisofs \
    -iso-level 3 \
    -full-iso9660-filenames \
    -volid "NOXYGENOS" \
    -eltorito-boot isolinux/isolinux.bin \
    -eltorito-catalog isolinux/boot.cat \
    -no-emul-boot \
    -boot-load-size 4 \
    -boot-info-table \
    -isohybrid-mbr /usr/lib/ISOLINUX/isohdpfx.bin \
    -output "$ISO_OUTPUT_DIR/${DISTRO_NAME}.iso" \
    "$WORK_DIR/image"

echo "[*] Noxygen ISO build complete!"
echo "[*] You can now burn this ISO to a USB drive or boot it in a VM"

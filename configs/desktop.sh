#!/bin/bash
echo "[*] Setting up desktop environment and user..."

# Create noxygen user with full root privileges
useradd -m -s /bin/zsh -G wheel,audio,video,network,storage noxygen
echo "noxygen:noxygen" | chpasswd

# Setup desktop directories for noxygen user
mkdir -p /home/noxygen/Desktop
mkdir -p /home/noxygen/Documents
mkdir -p /home/noxygen/Downloads
mkdir -p /home/noxygen/Pictures
mkdir -p /home/noxygen/Scripts

# Copy desktop files for noxygen user
cp /root/.xinitrc /home/noxygen/.xinitrc
cp /root/.bash_profile /home/noxygen/.bash_profile

# Copy desktop shortcuts and info files
cp configs/desktop/INFO.md /home/noxygen/Desktop/
cp configs/desktop/Terminal.desktop /home/noxygen/Desktop/
cp configs/desktop/Browser.desktop /home/noxygen/Desktop/

# Set permissions for noxygen user
chown -R noxygen:noxygen /home/noxygen/
chmod +x /home/noxygen/Desktop/*.desktop

# Setup full root access for noxygen user
echo "noxygen ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Setup autologin for noxygen user
sed -i 's/--autologin root/--autologin noxygen/g' /etc/systemd/system/getty@tty1.service.d/autologin.conf

echo "[*] Desktop setup complete! User: noxygen (password: noxygen) with full root access"

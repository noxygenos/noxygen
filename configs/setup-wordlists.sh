#!/bin/bash
echo "[*] Setting up wordlists..."

# Create wordlists directory
mkdir -p /usr/share/wordlists

# Download rockyou.txt
echo "[*] Downloading rockyou.txt..."
wget -O /usr/share/wordlists/rockyou.txt.gz https://github.com/brannondorsey/naive-hashcat/releases/download/data/rockyou.txt
gunzip /usr/share/wordlists/rockyou.txt.gz 2>/dev/null || mv /usr/share/wordlists/rockyou.txt.gz /usr/share/wordlists/rockyou.txt

# Download SecLists
echo "[*] Downloading SecLists..."
git clone https://github.com/danielmiessler/SecLists.git /usr/share/wordlists/SecLists

# Download common wordlists
echo "[*] Downloading additional wordlists..."
mkdir -p /usr/share/wordlists/dirbuster
wget -O /usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt https://raw.githubusercontent.com/daviddias/node-dirbuster/master/lists/directory-list-2.3-medium.txt

# Set permissions
chmod -R 644 /usr/share/wordlists/
find /usr/share/wordlists/ -type d -exec chmod 755 {} \;

echo "[*] Wordlists setup complete!"

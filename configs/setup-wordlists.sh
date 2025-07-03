#!/bin/bash
echo "[*] Setting up wordlists..."

# Create wordlists directory
mkdir -p /usr/share/wordlists

# Download wordlists in parallel for speed
echo "[*] Downloading wordlists in parallel..."
mkdir -p /usr/share/wordlists/dirbuster

# Start parallel downloads
wget -O /usr/share/wordlists/rockyou.txt.gz https://github.com/brannondorsey/naive-hashcat/releases/download/data/rockyou.txt &
wget -O /usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt https://raw.githubusercontent.com/daviddias/node-dirbuster/master/lists/directory-list-2.3-medium.txt &

# Wait for all downloads to complete
wait

echo "[*] Wordlists downloaded successfully!"

# Set permissions
chmod -R 644 /usr/share/wordlists/
find /usr/share/wordlists/ -type d -exec chmod 755 {} \;

echo "[*] Wordlists setup complete!"

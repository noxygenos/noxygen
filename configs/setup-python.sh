#!/bin/bash
echo "[*] Installing uv (ultra-fast Python package manager)..."
curl -LsSf https://astral.sh/uv/install.sh | sh
export PATH="$HOME/.cargo/bin:$PATH"

echo "[*] Installing essential Python packages with uv..."

# Install base Python packages
uv pip install --system \
    requests beautifulsoup4 lxml \
    scapy paramiko netaddr ipaddress \
    pandas numpy matplotlib \
    pwntools python-nmap impacket \
    flask django fastapi \
    pycryptodome \
    openpyxl python-docx pillow \
    colorama termcolor rich click \
    httpx aiohttp

echo "[*] Python packages installation complete with uv!"

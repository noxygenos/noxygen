#!/bin/bash
echo "[*] Installing additional security tools for Ubuntu/Debian..."

# Add Kali Linux repository for additional tools
echo "[*] Adding Kali Linux repository..."
if ! grep -q "kali-rolling" /etc/apt/sources.list.d/kali.list 2>/dev/null; then
    echo "deb http://http.kali.org/kali kali-rolling main contrib non-free" > /etc/apt/sources.list.d/kali.list
    
    # Add Kali GPG key
    wget -q -O - https://archive.kali.org/archive-key.asc | apt-key add -
    
    # Set low priority for Kali packages to avoid conflicts
    cat > /etc/apt/preferences.d/kali.pref << EOF
Package: *
Pin: release o=Kali
Pin-Priority: 50
EOF
    
    apt update
fi

# Install packages from main repos first
echo "[*] Installing packages from main repositories..."
while read -r package; do
    if [[ ! "$package" =~ ^# ]] && [[ -n "$package" ]]; then
        echo "Installing: $package"
        apt install -y "$package" 2>/dev/null || echo "Warning: Could not install $package"
    fi
done < configs/packages-debian.txt

# Install additional Kali tools
echo "[*] Installing additional tools from Kali repository..."
apt install -y -t kali-rolling \
    bettercap \
    mitmproxy \
    sslsplit \
    hcxdumptool \
    hcxtools \
    wifite \
    mdk4 \
    python3-impacket \
    metasploit-framework \
    2>/dev/null || echo "Some Kali tools may not be available"


# Install additional tools via snap (if available)
if command -v snap &> /dev/null; then
    echo "[*] Installing tools via snap..."
    snap install burp-suite-proxy-edition 2>/dev/null || echo "Burp Suite not available via snap"
fi

# Install additional tools manually
echo "[*] Installing additional tools manually..."

# Install Go tools (skip in fast build mode)
if command -v go &> /dev/null && [ "${SKIP_HEAVY_TOOLS:-0}" != "1" ]; then
    echo "Installing Go-based tools..."
    export GOPATH=/opt/go
    export PATH=$PATH:$GOPATH/bin
    mkdir -p $GOPATH
    
    # Install tools in parallel for speed
    (go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest 2>/dev/null || true) &
    (go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest 2>/dev/null || true) &
    (go install -v github.com/projectdiscovery/nuclei/v2/cmd/nuclei@latest 2>/dev/null || true) &
    
    # Wait for all Go installs to complete
    wait
    
    # Make Go tools available system-wide
    cp $GOPATH/bin/* /usr/local/bin/ 2>/dev/null || true
elif [ "${SKIP_HEAVY_TOOLS:-0}" == "1" ]; then
    echo "Skipping Go tools (fast build mode)"
fi

# Install Rust tools if cargo is available (skip in fast build mode)
if command -v cargo &> /dev/null && [ "${SKIP_HEAVY_TOOLS:-0}" != "1" ]; then
    echo "Installing Rust-based tools..."
    (cargo install feroxbuster 2>/dev/null || true) &
    (cargo install rustscan 2>/dev/null || true) &
    wait
    cp ~/.cargo/bin/* /usr/local/bin/ 2>/dev/null || true
elif [ "${SKIP_HEAVY_TOOLS:-0}" == "1" ]; then
    echo "Skipping Rust tools (fast build mode)"
fi

echo "[*] Tool installation complete!"

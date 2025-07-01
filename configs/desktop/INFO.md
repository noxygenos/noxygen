# 🔥 NoxygenOS - Advanced Pentesting Distribution

## 🚀 Modern Tools Included
- **Rust-powered CLI tools**: `rg` (ripgrep), `fd`, `bat`, `eza`
- **Fast Python package manager**: `uv` 
- **Modern terminal**: `alacritty`
- **Secure browser**: `ungoogled-chromium`

## 🛡️ Red Team Arsenal
- **C2 Frameworks**: `metasploit`, `sliver`, `covenant`
- **MITM Tools**: `bettercap`, `mitmproxy`, `ettercap`
- **WiFi Testing**: `aircrack-ng`, `wifite2`, `eaphammer`
- **AD Testing**: `crackmapexec`, `impacket`, `bloodhound`
- **Web Testing**: Network tools, proxies, tunnels

## 📚 Resources
- **Wordlists**: `/usr/share/wordlists/` (rockyou.txt, SecLists)
- **Python packages**: Pre-installed with `uv`
- **Aliases**: Type `alias` to see shortcuts

## 👤 User
- **noxygen**: Password `noxygen` - Full root access with `sudo`

## 🚀 Aliases Available
**Modern tool replacements:**
- `grep` -> `rg` (ripgrep)
- `find` -> `fd` 
- `cat` -> `bat`
- `ls` -> `eza --color=auto`
- `ll` -> `eza -la --color=auto` (detailed list)
- `la` -> `eza -a --color=auto` (show hidden)
- `tree` -> `eza --tree`
- `top` -> `btop`
- `df` -> `duf`
- `du` -> `dust`

**Safe file operations:**
- `cp` -> `cp -iv` (interactive + verbose)
- `mv` -> `mv -iv` (interactive + verbose)  
- `rm` -> `rm -iv` (interactive + verbose)

**Quick navigation:**
- `..` -> `cd ..`
- `...` -> `cd ../..`
- `....` -> `cd ../../..`

**Pentesting shortcuts:**
- `nmap-quick <target>` - Fast TCP scan
- `nmap-full <target>` - Full aggressive scan  
- `gobuster-dir -u <url>` - Directory enumeration  
- `gobuster-dns -d <domain>` - DNS subdomain enum
- `nikto-scan <target>` - Web vulnerability scan
- `rockyou` - Direct path to rockyou.txt
- `wordlists` - Browse all wordlists

**Development:**
- `venv` -> `python -m venv` (create virtual environment)
- `activate` -> `source venv/bin/activate`
- `serve` -> `python -m http.server 8000`
- `serve-ssl` -> `python -m http.server 8443 --bind 0.0.0.0`

Built on Arch Linux with love from Zander Lewis <zander@zanderlewis.dev>

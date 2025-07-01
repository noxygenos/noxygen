# Modern Rust tool aliases
alias grep='rg'
alias find='fd'
alias cat='bat'

# Enhanced ls alternatives
alias ls='eza --color=auto'
alias ll='eza -la --color=auto'
alias la='eza -a --color=auto'
alias tree='eza --tree'

# System monitoring
alias top='btop'
alias df='duf'
alias du='dust'

# File operations
alias cp='cp -iv'
alias mv='mv -iv'
alias rm='rm -iv'

# Quick navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# Pentesting shortcuts
alias nmap-quick='nmap -T4 -F'
alias nmap-full='nmap -T4 -A -v'
alias gobuster-dir='gobuster dir -w /usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt'
alias gobuster-dns='gobuster dns -w /usr/share/wordlists/SecLists/Discovery/DNS/subdomains-top1million-5000.txt'
alias nikto-scan='nikto -h'
alias rockyou='/usr/share/wordlists/rockyou.txt'
alias wordlists='cd /usr/share/wordlists && ls -la'

# Python virtual environment
alias venv='python -m venv'
alias activate='source venv/bin/activate'

# Quick file serving
alias serve='python -m http.server 8000'
alias serve-ssl='python -m http.server 8443 --bind 0.0.0.0'

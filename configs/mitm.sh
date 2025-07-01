#!/bin/bash
IFACE=$(ip route | grep default | awk '{print $5}')
if command -v bettercap &>/dev/null && [ -n "$IFACE" ]; then
  echo "[*] Starting bettercap on $IFACE..."
  nohup bettercap -iface $IFACE > /tmp/bettercap.log 2>&1 &
fi

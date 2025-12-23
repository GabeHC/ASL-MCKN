#!/bin/bash
set -euo pipefail

REPO_RAW="https://raw.githubusercontent.com/GabeHC/ASL-MCKN/main"

MCKN_DST="/usr/local/sbin/mckn.sh"
STATE_BASE="/var/lib/asterisk/state"
RPTCONF="/etc/asterisk/rpt.conf"

echo "=== ASL-MCKN setup starting ==="

# Root check
if [[ "${EUID:-0}" -ne 0 ]]; then
  echo "ERROR: Please run as root (sudo or su -)"
  exit 1
fi

# Dependencies (best effort; HamVoIP often uses pacman)
echo "[*] Installing dependencies (best effort)..."
if command -v apt >/dev/null 2>&1; then
  apt update
  apt install -y curl util-linux awk
elif command -v pacman >/dev/null 2>&1; then
  pacman -Sy --noconfirm curl util-linux awk || true
else
  echo "WARNING: No apt/pacman found. Ensure curl, flock (util-linux), and awk exist."
fi

# Install mckn.sh
echo "[*] Installing mckn.sh..."
mkdir -p /usr/local/sbin "$STATE_BASE"
curl -fsSL "$REPO_RAW/mckn.sh" -o "$MCKN_DST"
chmod 755 "$MCKN_DST"
sed -i 's/\r$//' "$MCKN_DST" || true

# Make state writable for asterisk (DTMF macros)
if id asterisk >/dev/null 2>&1; then
  chown -R asterisk:asterisk "$STATE_BASE" || true
fi
chmod 755 "$STATE_BASE" || true

# Node detection (do not fail if grep finds nothing)
NODE="$(grep -E '^\s*node\s*=' "$RPTCONF" 2>/dev/null | head -n1 | cut -d= -f2 | tr -d ' ' || true)"
if [[ -z "${NODE:-}" ]]; then
  read -rp "Enter your AllStarLink node number: " NODE
fi

echo
read -rp "Auto-patch $RPTCONF to add C0–C4 macros for node ${NODE}? [Y/n] " ANS
ANS="${ANS:-Y}"

if [[ "$ANS" =~ ^([Yy]|[Yy][Ee][Ss])$ ]]; then
  if [[ ! -f "$RPTCONF" ]]; then
    echo "ERROR: Cannot find rpt.conf at $RPTCONF"
    exit 1
  fi

  echo "[*] Backing up rpt.conf..."
  cp "$RPTCONF" "${RPTCONF}.bak.$(date +%Y%m%d-%H%M%S)"

  echo "[*] Patching rpt.conf..."
  TMP_OUT="$(mktemp)"
  trap 'rm -f "$TMP_OUT"' EXIT

  awk -v node="$NODE" '
  BEGIN{
    in_funcs=0;
    funcs_found=0;
    inserted=0;
    skip_block=0;
    begin="; --- ASL-MCKN AUTO-PATCH BEGIN ---";
    end="; --- ASL-MCKN AUTO-PATCH END ---";
  }
  function print_block(){
    print begin;
    print "C0=cmd,/usr/local/sbin/mckn.sh " node " 0   ; reconnect last node (same mode)";
    print "C1=cmd,/usr/local/sbin/mckn.sh " node " 1   ; disconnect last node";
    print "C2=cmd,/usr/local/sbin/mckn.sh " node " 2   ; monitor most connected node";
    print "C3=cmd,/usr/local/sbin/mckn.sh " node " 3   ; transceive most connected node";
    print "C4=cmd,/usr/local/sbin/mckn.sh " node " 4   ; local monitor most connected node (74)";
    print end;
  }
  {
    if (skip_block==1){
      if ($0 ~ end) { skip_block=0; }
      next;
    }

    if ($0 ~ /^\[functions[0-9]+\]/){
      in_funcs = ($0 ~ ("^\\[functions" node "\\]"));
      if (in_funcs) funcs_found=1;
      print $0;

      if (in_funcs && inserted==0){
        print_block();
        inserted=1;
      }
      next;
    }

    if (in_funcs && $0 ~ begin){
      skip_block=1;
      next;
    }

    print $0;
  }
  END{
    if (funcs_found==0){
      print "";
      print "[functions" node "]";
      print_block();
    }
  }' "$RPTCONF" > "$TMP_OUT"

  cp "$TMP_OUT" "$RPTCONF"
  echo "[*] Done patching rpt.conf."
else
  echo "[*] Skipped rpt.conf patch."
fi

echo
echo "=== ASL-MCKN installation complete ==="
echo "Node number : $NODE"
echo
echo "Reload app_rpt after changing rpt.conf (ASL3 tested):"
echo "  asterisk -rx \"module reload app_rpt.so\""
echo
echo "73 de BV5DJ"

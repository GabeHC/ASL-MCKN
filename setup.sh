#!/bin/bash
set -e

REPO_RAW="https://raw.githubusercontent.com/GabeHC/ASL-MCKN/main"

MCKN_DST="/usr/local/sbin/mckn.sh"
STATE_DIR="/var/lib/asterisk/state"
RPTCONF="/etc/asterisk/rpt.conf"

echo "=== ASL-MCKN setup starting ==="

# ----------------------------
# Root check
# ----------------------------
if [[ "$EUID" -ne 0 ]]; then
  echo "ERROR: Please run as root (sudo or su -)"
  exit 1
fi

# ----------------------------
# Dependencies
# ----------------------------
echo "[*] Installing dependencies..."
if command -v apt >/dev/null 2>&1; then
  apt update
  apt install -y curl util-linux
elif command -v pacman >/dev/null 2>&1; then
  pacman -Sy --noconfirm curl util-linux
else
  echo "WARNING: Unknown package manager; ensure curl + flock are installed."
fi

# ----------------------------
# Install files
# ----------------------------
echo "[*] Installing files..."
mkdir -p /usr/local/sbin "$STATE_DIR"

curl -fsSL "$REPO_RAW/mckn.sh" -o "$MCKN_DST"

chmod 755 "$MCKN_DST"
sed -i 's/\r$//' "$MCKN_DST"

chown -R asterisk:asterisk "$STATE_DIR"

# ----------------------------
# Auto-detect node number
# ----------------------------
NODE="$(grep -E '^\s*node\s*=' "$RPTCONF" 2>/dev/null | head -n1 | cut -d= -f2 | tr -d ' ')"

if [[ -z "$NODE" ]]; then
  echo
  read -rp "Enter your AllStarLink node number: " NODE
fi

FUNC_SECTION="[functions${NODE}]"

# ----------------------------
# Backup rpt.conf
# ----------------------------
echo "[*] Backing up rpt.conf..."
cp "$RPTCONF" "${RPTCONF}.bak.$(date +%Y%m%d-%H%M%S)"

# ----------------------------
# Ensure function section exists
# ----------------------------
if ! grep -q "^\[functions${NODE}\]" "$RPTCONF"; then
  echo
  echo "[*] Creating $FUNC_SECTION"
  cat >> "$RPTCONF" <<EOF

$FUNC_SECTION
; --- ASL-MCKN AUTO-PATCH BEGIN ---
; (entries added by setup.sh)
; --- ASL-MCKN AUTO-PATCH END ---
EOF
fi

# ----------------------------
# Insert macros (idempotent)
# ----------------------------
echo "[*] Patching ASL-MCKN macros..."

PATCH_BLOCK=$(cat <<EOF
; --- ASL-MCKN AUTO-PATCH BEGIN ---
C0=cmd,/usr/local/sbin/mckn.sh $NODE 0   ; reconnect last node
C1=cmd,/usr/local/sbin/mckn.sh $NODE 1   ; disconnect last node
C2=cmd,/usr/local/sbin/mckn.sh $NODE 2   ; monitor most connected
C3=cmd,/usr/local/sbin/mckn.sh $NODE 3   ; transceive most connected
C4=cmd,/usr/local/sbin/mckn.sh $NODE 4   ; local monitor (74)
; --- ASL-MCKN AUTO-PATCH END ---
EOF
)

# Remove old block if exists
sed -i "/; --- ASL-MCKN AUTO-PATCH BEGIN ---/,/; --- ASL-MCKN AUTO-PATCH END ---/d" "$RPTCONF"

# Insert block after function header
sed -i "/^\[functions${NODE}\]/a $PATCH_BLOCK" "$RPTCONF"

# ----------------------------
# Done
# ----------------------------
echo
echo "=== ASL-MCKN installation complete ==="
echo
echo "Node number : $NODE"
echo "Macros added: C0–C4"
echo
echo "Reload Asterisk:"
echo "  asterisk -rx \"rpt reload\""
echo
echo "73 de BV5DJ"

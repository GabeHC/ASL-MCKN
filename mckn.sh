#!/bin/bash
set -euo pipefail

# ============================
# Args & defaults
# ============================
NODE="${1:-60143}"
MODE_IN="${2:-2}"

# Map ASL mode 4 -> 74 (local monitor)
MODE="$MODE_IN"
if [[ "$MODE" == "4" ]]; then
  MODE="74"
fi

case "$MODE" in
  0|1|2|3|74) ;;
  *)
    echo "Invalid mode: $MODE_IN"
    exit 1
    ;;
esac

# ============================
# Paths (per-node)
# ============================
STATE_DIR="/var/lib/asterisk/state/${NODE}"
STATE_NODE="${STATE_DIR}/last_connected_node.txt"
STATE_MODE="${STATE_DIR}/last_mode.txt"
LOCKFILE="${STATE_DIR}/asl-mckn.lock"


mkdir -p "$STATE_DIR"

# ============================
# Lock (DTMF-safe)
# ============================
exec 9>"$LOCKFILE" || exit 1
flock -n 9 || exit 0

# ============================
# Load state
# ============================
LAST_NODE=""
LAST_MODE="2"

[[ -s "$STATE_NODE" ]] && LAST_NODE="$(tr -d ' \r\n\t' < "$STATE_NODE")"
[[ -s "$STATE_MODE" ]] && LAST_MODE="$(tr -d ' \r\n\t' < "$STATE_MODE")"

case "$LAST_MODE" in
  2|3|74) ;;
  *) LAST_MODE="2" ;;
esac

# ============================
# Mode 1: Disconnect last node
# ============================
if [[ "$MODE" == "1" ]]; then
  if [[ -z "$LAST_NODE" ]]; then
    echo "No last node to disconnect"
    exit 0
  fi
  asterisk -rx "rpt fun $NODE *1$LAST_NODE"
  exit 0
fi

# ============================
# Mode 0: Reconnect last node
# ============================
if [[ "$MODE" == "0" ]]; then
  if [[ -z "$LAST_NODE" ]]; then
    echo "No last node to reconnect"
    exit 1
  fi
  asterisk -rx "rpt fun $NODE *${LAST_MODE}${LAST_NODE}"
  exit 0
fi

# ============================
# Find most-connected keyed node (robust)
# ============================
TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT

curl -fsSL "http://stats.allstarlink.org/stats/keyed" -o "$TMP"

# Extract node IDs and pick the most frequent one (excluding LAST_NODE if set)
BEST_NODE="$(
  grep -o '/stats/[0-9]\+' "$TMP" \
  | sed 's|/stats/||' \
  | { if [[ -n "${LAST_NODE:-}" ]]; then grep -v "^${LAST_NODE}$"; else cat; fi; } \
  | sort \
  | uniq -c \
  | sort -nr \
  | awk 'NR==1 {print $2}'
)"

if [[ -z "$BEST_NODE" ]]; then
  echo "No suitable node found"
  exit 1
fi

# ============================
# Connect & save state
# ============================
asterisk -rx "rpt fun $NODE *${MODE}${BEST_NODE}"

echo "$BEST_NODE" > "$STATE_NODE"
echo "$MODE" > "$STATE_MODE"

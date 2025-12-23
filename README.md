# ASL-MCKN – Most Connected Keyed Node Utility

ASL-MCKN is a shared utility for **AllStarLink (ASL)** systems that automatically connects a node to the **most connected keyed node** on the network, with support for reconnecting, disconnecting, and multiple connection modes.

It is designed to be:
- Safe for DTMF macros
- Reboot-persistent
- Multi-node friendly
- Easy to deploy with one command

---

## Features

- Connect to most connected keyed node
- Reconnect last node with same mode
- Disconnect last connected node
- Per-node persistent state
- Auto-patch `rpt.conf`

---

## Requirements

- AllStarLink / HamVOIP
- Bash
- curl
- asterisk

---

## Quick Install (Recommended)

```bash
wget https://raw.githubusercontent.com/GabeHC/ASL-MCKN/main/setup.sh
chmod +x setup.sh
sudo ./setup.sh
```

The installer will:
- Install required files
- Create persistent state directories
- Auto-detect your node number
- Patch `rpt.conf` safely
- Add C0–C4 DTMF macros

---

## DTMF Commands (Auto-Installed)

| DTMF | Function |
|-----|----------|
| C0 | Reconnect last node (same mode) |
| C1 | Disconnect last connected node |
| C2 | Monitor most connected node |
| C3 | Transceive most connected node |
| C4 | Local monitor most connected node |

---

## Manual Usage

```bash
mckn.sh <NODE> <MODE>
```

Modes:

- 0 – Reconnect last node
- 1 – Disconnect last node
- 2 – Monitor most connected
- 3 – Transceive most connected
- 4 – Local monitor (mapped to ASL 74)

---

## Persistent State

State is stored per node:

```
/var/lib/asterisk/state/<NODE>/
 ├── last_connected_node.txt
 └── last_mode.txt
```

This survives reboots and works reliably from DTMF macros.

---

## Shared Utility Design

Files installed:

```
/usr/local/sbin/mckn.sh
```

---

## Safety Notes

- Installer backs up `rpt.conf` before modifying
- Macros are idempotent (safe to re-run setup)
- Uses absolute paths only
- Prevents double execution from rapid DTMF presses

---

## License

MIT License

---

73 de **BV5DJ**

# ASL-MCKN – Most Connected Keyed Node Utility

ASL-MCKN provides a simple way to connect your AllStarLink node to the **most-connected keyed node** shown on the AllStarLink stats page, and to manage reconnect/disconnect via DTMF macros.

## Features
- Connect to most-connected keyed node (based on current stats)
- Reconnect last connected node (same mode)
- Disconnect last connected node
- Persistent per-node state (survives reboot)
- One-command install with optional `rpt.conf` auto-patch

## Requirements
- AllStarLink / HamVOIP / ASL3
- Bash
- curl
- asterisk
- util-linux (for `flock`)
- awk (for setup auto-patch)

## Quick install (recommended)

```bash
wget https://raw.githubusercontent.com/GabeHC/ASL-MCKN/main/setup.sh
chmod +x setup.sh
sudo ./setup.sh
```

The installer will:
- install `/usr/local/sbin/mckn.sh`
- create state directory: `/var/lib/asterisk/state/<NODE>/`
- (optional) patch `/etc/asterisk/rpt.conf` to add C0–C4 macros under `[functions<NODE>]`
- make a timestamped backup of `rpt.conf` before changes

## DTMF macros (C0–C4)

These are the macros the setup script can add to `[functions<NODE>]` in `rpt.conf`:

```ini
C0=cmd,/usr/local/sbin/mckn.sh <NODE> 0   ; reconnect last node (same mode)
C1=cmd,/usr/local/sbin/mckn.sh <NODE> 1   ; disconnect last node
C2=cmd,/usr/local/sbin/mckn.sh <NODE> 2   ; monitor most connected node
C3=cmd,/usr/local/sbin/mckn.sh <NODE> 3   ; transceive most connected node
C4=cmd,/usr/local/sbin/mckn.sh <NODE> 4   ; local monitor most connected node (maps to 74)
```

Reload after editing / patching:

- **ASL3 (tested):**
```bash
asterisk -rx "module reload app_rpt.so"
```
- **HamVoIP:** the same command works; if you prefer, you can restart Asterisk.

## Manual usage

```bash
mckn.sh <NODE> <MODE>
```

Modes:
- `0` – reconnect last node using last saved mode
- `1` – disconnect last connected node
- `2` – connect most-connected node in **monitor**
- `3` – connect most-connected node in **transceive**
- `4` – connect most-connected node in **local monitor** (mapped to ASL `74`)

## Persistent state

Per-node state is stored here:

```
/var/lib/asterisk/state/<NODE>/
 ├── last_connected_node.txt
 └── last_mode.txt
```

## Notes about locking

DTMF macros can be triggered multiple times quickly (double-press, retries, RF decoding). `mckn.sh` uses a small lock file to prevent two instances running at once.

## License
MIT

73 de **BV5DJ**

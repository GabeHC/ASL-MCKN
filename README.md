---

# mckn.sh - Most Connected Keyed Node

This Bash script, **mckn.sh**, assists in automatically connecting an AllStarLink node to the most connected keyed node found on the AllStarLink network.

It retrieves connection information from the AllStarLink statistics page and connects your node to the node with the highest number of active connections, while avoiding reconnecting to the previously connected node.

The script is designed to be **safe for ASL DTMF macros**, supports **persistent state storage**, and provides a **reconnect-to-last-node** feature.

---

## Requirements

- Bash (Bourne Again Shell)
- `curl`
- `asterisk`
- AllStarLink (ASL 2 / ASL 3 / HamVOIP compatible)

---

## Usage

### Running the Script

1. Clone this repository or download the script (`mckn.sh`).
2. Make sure the script is executable:

   ```bash
   chmod +x mckn.sh
   ```

3. Run the script:

   ```bash
   ./mckn.sh [your_node_number] [connection_mode]
   ```

---

## Parameters

- `your_node_number` (optional)  
  Your AllStarLink node number.  
  Default: `50445`

- `connection_mode` (optional):

| Mode | Description |
|------|------------|
| `0`  | Reconnect to the **last connected node** using the **last saved mode** |
| `2`  | Monitor mode (default) |
| `3`  | Transceive mode |
| `74` | Local monitor mode |

---

## Example

```bash
./mckn.sh 12345 3
```

This command connects node `12345` using **Transceive mode** to the most connected node found by the script.

---

## Integration with AllStarLink DTMF Control

To activate the script from DTMF control in AllStarLink, add macros to your `rpt.conf` configuration file.

### Example

1. Open your `rpt.conf` file:

   ```bash
   nano /etc/asterisk/rpt.conf
   ```

2. Add the following lines for node **12345**:

   ```ini
   [functions12345]

   A2=cmd,/usr/local/sbin/mckn.sh 12345 2   ; connect most-connected (monitor)
   A3=cmd,/usr/local/sbin/mckn.sh 12345 3   ; connect most-connected (transceive)
   A4=cmd,/usr/local/sbin/mckn.sh 12345 74  ; connect most-connected (local monitor)
   A0=cmd,/usr/local/sbin/mckn.sh 12345 0   ; reconnect last node (reuse last mode)
   ```

3. Reload Asterisk:

   ```bash
   asterisk -rx "rpt reload"
   ```

Pressing the corresponding DTMF keys will execute the `mckn.sh` script.

---

## Avoiding Last Connected Node

When selecting the most connected node, the script avoids reconnecting to the **previously connected node** to prevent rapid reconnect loops.

---

## Mode `0` – Reconnect Last Node

Mode `0` reconnects to the **last connected node** using the **same connection mode** (`2`, `3`, or `74`) that was used previously.

Example:

```bash
./mckn.sh 12345 0
```

This is useful after:
- Node reboots
- Link drops
- Temporary disconnects

---

## Persistent State Files

Runtime state is stored persistently under:

```
/var/lib/asterisk/state/
 ├── last_connected_node.txt
 └── last_mode.txt
```

These files:
- Survive reboots
- Work reliably when triggered by ASL macros
- Eliminate working-directory issues with Asterisk

### One-time setup

```bash
sudo mkdir -p /var/lib/asterisk/state
sudo chown -R asterisk:asterisk /var/lib/asterisk/state
sudo chmod 755 /var/lib/asterisk/state
```

---

## Notes on ASL Safety

- Absolute paths are used throughout the script
- A lock file prevents double execution from rapid DTMF presses
- Temporary files are created using `mktemp` and cleaned automatically

These refinements make `mckn.sh` safe and predictable when run from:
- DTMF commands
- ASL macros
- CLI
- Cron jobs

---

## License

This project is licensed under the [MIT License](LICENSE).

---

73 de **BV5DJ**

---

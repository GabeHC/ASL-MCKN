---

# mckn.sh - Most Connected Keyed Node

This Bash script, **mckn.sh**, assists in automatically connecting an Allstarlink node to the most connected node found in the Allstarlink network. It retrieves information about node connections from the Allstarlink statistics page and connects your node to the node with the highest number of connections.

## Requirements

- Bash (Bourne Again Shell)
- curl
- asterisk

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

### Parameters

- `your_node_number` (optional): Your Allstarlink node number. If not provided, the script will default to `50445`.
- `connection_mode` (optional): The connection mode to use (2 or 3). If not provided, the script will default to `2`.

### Example

```bash
./mckn.sh 12345 3
```

This command will connect your Allstarlink node with number `12345` using connection mode `3` to the most connected node found by the script.

### Integration with Allstarlink DTMF Control

To activate the script from DTMF control in Allstarlink, you can add a macro to your `rpt.conf` configuration file. Here's an example of how to add the macro:

1. Open your `rpt.conf` file for editing:
   ```bash
   nano /etc/asterisk/rpt.conf
   ```
2. Add the following lines to define a macro named `MCKN` that runs the script when activated by the `*A2` DTMF key:
   ```ini
   [macro MCKN]
   ; Activate the Most Connected Keyed Node script
   ; Replace 12345 with your node number and 3 with the desired connection mode
   exten => s,1,System(/path/to/mckn.sh 12345 3)
   exten => s,n,Playback(silence/1)
   exten => s,n,Hangup()
   
   [your_node_number]
   ; Your existing node configuration...
   ; Add the following line to associate the macro with the *A2 DTMF key
   29=*A2,MCKN
   ```
3. Save and exit the file.

Now, pressing the `*A2` key on your Allstarlink node's DTMF control will activate the `MCKN` macro, which in turn runs the `mckn.sh` script to connect your node to the most connected node.

Make sure to replace `/path/to/mckn.sh` with the actual path to your `mckn.sh` script, and replace `12345` with your Allstarlink node number and `3` with your desired connection mode.

## License

This project is licensed under the [MIT License](LICENSE).

---



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
- `connection_mode` (optional): The connection mode to use (2 for monitor and 3 for Transceive). If not provided, the script will default to `2`.

### Example

```bash
./mckn.sh 12345 3
```

This command will connect your Allstarlink node with number `12345` using connection mode `3` to the most connected node found by the script.

## License

This project is licensed under the [MIT License](LICENSE).

---

Feel free to further customize the README if needed. If you have any questions or need further assistance, please let me know!

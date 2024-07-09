#!/bin/bash

# Set default values
your_node_number="50445"
connection_mode="2"

# Check if the correct number of parameters is provided
if [ "$#" -ge 1 ]; then
    your_node_number="$1"
fi

if [ "$#" -ge 2 ]; then
    connection_mode="$2"
fi

# Validate connection mode
if [ "$connection_mode" != "2" ] && [ "$connection_mode" != "3" ] && [ "$connection_mode" != "74" ] ; then
    echo "Connection mode must be 2, 3 or 74."
    exit 1
fi

# Load last connected node from environment variable
LAST_CONNECTED_NODE="$LAST_CONNECTED_NODE"

# Download the HTML content of the page
curl -s http://stats.allstarlink.org/stats/keyed > page.html

# Initialize variables to store the most connected node and its count
most_connected_node=""
max_connections=0

# Read each line of the HTML file
while IFS= read -r line; do
    # Check if the line contains a node number
    if [[ "$line" == *'<td><a href="/stats/'* ]]; then
        # Extract the node number
        new_node=$(echo "$line" | grep -oP '(?<=/stats/)[0-9]+')
        # Only update current_node if new_node is not empty
        if [[ -n "$new_node" ]]; then
            current_node="$new_node"
        fi
        connection_count=0
    fi

    # Check if the line contains connected nodes
    if [[ "$line" == *'<a href="/stats/'* ]]; then
        # Increment the connection count
        ((connection_count++))
    fi

    # Check if it's the end of the table row
    if [[ "$line" == *'</tr>'* ]]; then
        # Print the node and its number of connections
        echo "Node $current_node: $connection_count connections"

        # Update the most connected node if necessary and skip LAST_CONNECTED_NODE
        if [[ "$connection_count" -gt "$max_connections" && "$current_node" != "$LAST_CONNECTED_NODE" ]]; then
            max_connections=$connection_count
            most_connected_node=$current_node
        fi
    fi
done < page.html

# Print the most connected node
echo "Most connected node: $most_connected_node with $max_connections connections"

# Connect to the most connected node using Allstarlink if it's not empty
if [[ -n "$most_connected_node" ]]; then
    echo "Connecting to node $most_connected_node..."
    # Replace 'your_node_number' with your node number and 'connection_mode' with the provided connection mode
    asterisk -rx "rpt fun $your_node_number *$connection_mode$most_connected_node"
    
    # Update LAST_CONNECTED_NODE environment variable
    export LAST_CONNECTED_NODE="$most_connected_node"
else
    echo "No most connected node found."
fi

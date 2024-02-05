#!/bin/bash

# Function to check the link status of slave interfaces
function check_slave_links() {
    log_message "find_interface_ip_and_set" "DEBUG" "check_slave_links"
    for interface in "${slave_interfaces[@]}"; do
        # Get the carrier status from 'ip link'
        local carrier_status=$(ip link show "$interface" | grep -oP 'state \K\w+')

        # Get the connection state from 'nmcli device'
        local connection_state=$(nmcli -t -f DEVICE,STATE device | grep "^$interface" | cut -d: -f2)

        # Check if either carrier status is UP or LOWER_UP, or connection state is connected
        if [[ "$carrier_status" == "UP" || "$carrier_status" == "LOWER_UP" || "$connection_state" == "connected" ]]; then
            log_message "find_interface_ip_and_set" "DEBUG" "check_slave_links: At least one slave interface ($interface) is up."
            return 0
        fi
    done

    log_message "find_interface_ip_and_set" "DEBUG" "check_slave_links: No slave interfaces are up."
    return 1
}

# Usage
#if check_slave_links; then
#    echo "One or more slave interfaces are up and running."
#else
#    echo "No slave interfaces are up."
#fi

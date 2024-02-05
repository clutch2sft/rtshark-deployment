#!/bin/bash

# Function to check if an interface has a valid statically assigned IP
function check_static_ip() {
    local interface_name="$1"

    # Retrieve the IP method and addresses for the interface
    local ip_method=$(nmcli -g ipv4.method con show "$interface_name")
    local ip_addresses=$(nmcli -g ipv4.addresses con show "$interface_name")

    # Check if the method is manual (static) and if an IP address is assigned
    if [[ "$ip_method" == "manual" && ! -z "$ip_addresses" ]]; then
        log_message "find_interface_ip_and_set" "DEBUG" "check_static_ip: $interface_name has a statically assigned IP: $ip_addresses"
        return 0
    else
        log_message "find_interface_ip_and_set" "DEBUG" "check_static_ip: $interface_name does not have a statically assigned IP."
        return 1
    fi
}

# Usage
#interface_name="br0"
#if check_static_ip "$interface_name"; then
#    echo "check_static_ip: Static IP check passed."
#else
#    echo "check_static_ip: Static IP check failed."
#fi

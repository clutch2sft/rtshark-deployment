#!/bin/bash

check_interface_dhcp() {
    local interface_name=$1
    log_message $SCRIPT_NAME "DEBUG" "check_interface_dhcp"
    # Get the general state of the interface
    local general_state=$(nmcli -t -f GENERAL.STATE con show "$interface_name" | cut -d: -f2)

    # If the interface is not in the 'activated' state, it's not up and running
    if [[ "$general_state" != "activated" ]]; then
        log_message $SCRIPT_NAME "DEBUG" "check_interface_dhcp: Interface $interface_name is not activated."
        return 1
    fi

    # Check if the interface has a DHCP lease time, which indicates a DHCP IP
    local dhcp_lease_time=$(nmcli -t -f DHCP4.OPTION con show "$interface_name" | grep 'dhcp_lease_time')

    if [[ -n "$dhcp_lease_time" ]]; then
        log_message $SCRIPT_NAME "DEBUG" "check_interface_dhcp: Interface $interface_name has a DHCP assigned IP."
        return 0
    else
        log_message $SCRIPT_NAME "DEBUG" "check_interface_dhcp: Interface $interface_name does not have a DHCP assigned IP."
        return 1
    fi
}

# Usage
#INTERFACE="br0"
#if check_interface_dhcp "$INTERFACE"; then
#    echo "$INTERFACE has a DHCP IP."
#else
#    echo "$INTERFACE does not have a DHCP IP or is not in the correct state."
#fi

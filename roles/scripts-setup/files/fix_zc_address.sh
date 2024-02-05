#!/bin/bash

run_arping() {
    local ip=$1
    local arping_cmd
    local arping_output
    local arping_exit_status

    # Define a list of potential arping command variations
    local arping_variations=(
        "-0 -c 2 -w 3 -I $INTERFACE $ip"
        "-s 0.0.0.0 -c 2 -w 3 -I $INTERFACE $ip"
        "-S 0.0.0.0 -c 2 -w 3 -I $INTERFACE $ip"
    )

    # Iterate over each variation and test
    for variation in "${arping_variations[@]}"; do

        arping_cmd="arping $variation"
        arping_output=$($arping_cmd 2>&1)
        arping_exit_status=$?
        log_message "find_interface_ip_and_set" "DEBUG" "Arping comand is:$variation output is:$arping_output statuscode is:$arping_exit_status"

        # Check the exit status of the arping command
        if [[ $arping_exit_status -eq 0 ]]; then
            # Success, IP address is in use
            return 1
        elif [[ $arping_exit_status -eq 1 ]]; then
            # No response, IP address is likely not in use
            return 0
        elif [[ $arping_exit_status -eq 2 ]]; then
            # Invalid option error, try the next variation
            continue
        else
            # Some other error, try the next variation
            log_message "my-ip-monitor" "ERROR" "arping error: $arping_output"
            continue
        fi
    done
    # All variations tried and none succeeded
    log_message "my-ip-monitor" "ERROR" "arping failed: incompatible options or other errors"
    return 2
}


fix_zc_address() {
    local NETWORK_PREFIX=$1
    local START_IP=$2
    local END_IP=$3
    local INTERFACE=$4

    local AVAILABLE_IP=""
    local AVAILABLE_GW="$NETWORK_PREFIX.1"

    for ip in $(seq "$START_IP" -1 "$END_IP"); do
        if run_arping "$NETWORK_PREFIX.$ip"; then
            log_message "find_interface_ip_and_set" "INFO" "Available IP: $NETWORK_PREFIX.$ip"
            AVAILABLE_IP="$NETWORK_PREFIX.$ip"
            break
        else
            log_message $SCRIPT_NAME "DEBUG" "fix_zc_address: IP $NETWORK_PREFIX.$ip is in use. Checking next."
        fi
    done

    # Check if an available IP was found
    if [ -z "$AVAILABLE_IP" ]; then
         log_message $SCRIPT_NAME "DEBUG" "fix_zc_address: No available $NETWORK_PREFIX.x addresses in the specified range. Exiting."
        return 1
    else
        log_message $SCRIPT_NAME "DEBUG" "fix_zc_address: Assigning new IP:$AVAILABLE_IP and gateway:$AVAILABLE_GW to $INTERFACE"
        nmcli con down "$INTERFACE"
        nmcli con mod "$INTERFACE" ipv4.method auto
        nmcli con mod "$INTERFACE" ipv4.gateway ""
        nmcli con mod "$INTERFACE" ipv4.addresses ""
        nmcli con mod "$INTERFACE" ipv4.method manual ipv4.addresses "$AVAILABLE_IP"/24 ipv4.gateway "$AVAILABLE_GW"
        nmcli con up "$INTERFACE"
        return 0
    fi
}

# Usage:
# fix_zc_address "NETWORK_PREFIX" "START_IP" "END_IP" "INTERFACE"
#fix_zc_address "192.168.1" 100 150 "eth0"

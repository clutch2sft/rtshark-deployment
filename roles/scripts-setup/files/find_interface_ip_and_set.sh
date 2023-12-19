#!/bin/bash

# Get the directory where the script is located
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [[ -f "$DIR/logging.inc" ]]; then
    # shellcheck disable=SC1091
    . "$DIR/logging.inc"
else
    echo "Error: logging.inc not found."
    exit 1
fi
if [[ -f "$DIR/rtshark-scripts-settings.inc" ]]; then
    # shellcheck disable=SC1091
    . "$DIR/rtshark-scripts-settings.inc"
else
    echo "Error: rtshark-scripts-settings.inc not found."
    exit 1
fi



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

# Function to check if br0 has a valid IP address
check_interface_ip() {
    local ip_address
    local max_attempts=30  # Number of attempts (with a 1-second delay between each)
    local attempt=0

    while [ $attempt -lt $max_attempts ]; do
        ip_address=$(nmcli -g IP4.ADDRESS dev show $INTERFACE | cut -d'/' -f1)

        if [[ "$ip_address" =~ ^169\.254\. ]]; then
            log_message "find_interface_ip_and_set" "INFO" "$INTERFACE has a Zeroconf address: $ip_address. Proceeding to check for available IPs."
            return  # Proceed with the rest of the script
        elif [ -n "$ip_address" ]; then
            log_message "find_interface_ip_and_set" "INFO" "$INTERFACE has a valid non-Zeroconf IP address: $ip_address. Exiting."
            exit 0  # Exit the script as a valid IP address is assigned
        else
            log_message "find_interface_ip_and_set" "DEBUG" "Waiting for IP address to be assigned to $INTERFACE (attempt $((attempt + 1))/$max_attempts)."
            sleep 1
        fi

        ((attempt++))
    done

    log_message "find_br0_ip_and_set" "WARN" "$INTERFACE did not receive an IP address within the expected time frame. Proceeding with IP assignment."
}

# Check br0 for a valid IP address
check_interface_ip


AVAILABLE_IP=""
for ip in $(seq $START_IP -1 $END_IP); do
    if run_arping $NETWORK_PREFIX.$ip; then
        log_message "INFO" "Available IP: $NETWORK_PREFIX.$ip"
        AVAILABLE_IP="$NETWORK_PREFIX.$ip"
        AVAILABLE_GW="$NETWORK_PREFIX.1"
        break
    else
        log_message "find_interface_ip_and_set" "DEBUG" "IP $NETWORK_PREFIX.$ip is in use. Checking next."
    fi
done

# Check if an available IP was found
if [ -z "$AVAILABLE_IP" ]; then
    log_message "find_interface_ip_and_set" "WARN" "No available $NETWORK_PREFIX.x addresses in the specified range. Exiting."
    exit 1
else
    log_message "find_interface_ip_and_set" "INFO" "Assigning new IP:$AVAILABLE_IP and gateway:$AVAILABLE_GW to $INTERFACE"
    nmcli con down $INTERFACE
    nmcli con mod $INTERFACE ipv4.method auto
    nmcli con mod $INTERFACE ipv4.gateway ""
    nmcli con mod $INTERFACE ipv4.addresses ""
    nmcli con mod $INTERFACE ipv4.method manual ipv4.addresses $AVAILABLE_IP/24 ipv4.gateway $AVAILABLE_GW
    nmcli con up $INTERFACE
fi

exit 0

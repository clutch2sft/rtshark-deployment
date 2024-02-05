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

# Override INTERFACE if an argument is provided
if [[ -n "$1" ]]; then
    INTERFACE="$1"
fi

# Override NETWORK_PREFIX if a second argument is provided
if [[ -n "$2" ]]; then
    NETWORK_PREFIX="$2"
fi
# Introduce a delay to wait for DHCP to potentially fail
SLEEP_DURATION=120  # 120 seconds, adjust as needed
log_message "find_interface_ip_and_set" "INFO" "Waiting for $SLEEP_DURATION seconds to allow DHCP to complete..."
sleep $SLEEP_DURATION

# Function to wait for a slave link to be established
wait_for_slave_link() {
    local max_attempts=30  # Modify as needed
    local attempt=0
    local slave_link_state
    local con_name="$INTERFACE"

    echo "Waiting for slave link to be established for $con_name..."

    while [ $attempt -lt $max_attempts ]; do
        # Check the state of the slave link here (modify the command based on how you determine the slave link state)
        slave_link_state=$(nmcli con show "$con_name" | grep 'your-specific-parameter-here')

        if [[ -n "$slave_link_state" ]]; then
            echo "Slave link established for $con_name."
            return 0
        else
            echo "Waiting for slave link... Attempt $((attempt + 1))/$max_attempts."
            sleep 5
        fi

        ((attempt++))
    done

    echo "Slave link not established for $con_name within the expected time frame."
    return 1
}




# Function to check the status of the connection after the delay
check_connection_status() {
    local con_name="$INTERFACE"
    local state
    local ip_address

    state=$(nmcli con show "$con_name" | grep 'connection.interface-name' | awk '{print $2}')
    ip_address=$(nmcli -g IP4.ADDRESS con show "$con_name" | cut -d'/' -f1)

    if [[ -n "$state" ]] && [[ -n "$ip_address" ]]; then
        log_message "find_interface_ip_and_set" "INFO"  "DHCP has successfully configured $con_name with IP address $ip_address."
        exit 0
    else
        log_message "find_interface_ip_and_set" "INFO" "$con_name is not correctly managed by DHCP or has no IP address."
    fi
}


#put a "valid ip" on the interface so it isn't down when we do arping.
handle_unmanaged_con() {
    local con_name="$INTERFACE"
    
    echo "Attempting to manage and configure $con_name with a static Zeroconf address."

    # Bring the connection down
    # Don't need to do this it is already down or we wouldn't be here.
    #nmcli con down "$con_name" || log_message "find_interface_ip_and_set" "INFO" "Failed to bring down $con_name"

    # Set static IP (Zeroconf address)
    nmcli con mod "$con_name" ipv4.method manual ipv4.addresses "$ZC_IP"/16 ipv4.gateway "$ZC_GW" || log_message "find_interface_ip_and_set" "INFO" "Failed to set IP for $con_name"

    # Set the connection to autoconnect
    nmcli con mod "$con_name" connection.autoconnect yes || log_message "find_interface_ip_and_set" "INFO" "Failed to set autoconnect for $con_name"

    # Bring the connection up
    nmcli con up "$con_name" || log_message "find_interface_ip_and_set" "INFO" "Failed to bring up $con_name"

    # Give it some time to apply the settings and come up
    sleep 5
    log_message "find_interface_ip_and_set" "INFO" "Addresses is set $ZC_IP/16 ipv4.gateway $ZC_GW"
}


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

# # Function to check if br0 has a valid IP address
# check_interface_ip() {
#     local ip_address
#     local max_attempts=30  # Number of attempts (with a 1-second delay between each)
#     local attempt=0

#     while [ $attempt -lt $max_attempts ]; do
#         ip_address=$(nmcli -g IP4.ADDRESS dev show $INTERFACE | cut -d'/' -f1)

#         if [[ "$ip_address" =~ ^169\.254\. ]]; then
#             log_message "find_interface_ip_and_set" "INFO" "$INTERFACE has a Zeroconf address: $ip_address. Proceeding to check for available IPs."
#             return  # Proceed with the rest of the script
#         elif [ -n "$ip_address" ]; then
#             log_message "find_interface_ip_and_set" "INFO" "$INTERFACE has a valid non-Zeroconf IP address: $ip_address. Exiting."
#             exit 0  # Exit the script as a valid IP address is assigned
#         else
#             log_message "find_interface_ip_and_set" "DEBUG" "Waiting for IP address to be assigned to $INTERFACE (attempt $((attempt + 1))/$max_attempts)."
#             sleep 1
#         fi

#         ((attempt++))
#     done

#     log_message "find_interface_ip_and_set" "WARN" "$INTERFACE did not receive an IP address within the expected time frame. Proceeding with IP assignment."
# }

wait_for_slave_link

check_connection_status

handle_unmanaged_con

AVAILABLE_IP=""
for ip in $(seq "$START_IP" -1 "$END_IP"); do
    if run_arping "$NETWORK_PREFIX.$ip"; then
        log_message "find_interface_ip_and_set" "INFO" "Available IP: $NETWORK_PREFIX.$ip"
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
    nmcli con down "$INTERFACE"
    nmcli con mod "$INTERFACE" ipv4.method auto
    nmcli con mod "$INTERFACE" ipv4.gateway ""
    nmcli con mod "$INTERFACE" ipv4.addresses ""
    nmcli con mod "$INTERFACE" ipv4.method manual ipv4.addresses "$AVAILABLE_IP"/24 ipv4.gateway "$AVAILABLE_GW"
    nmcli con up "$INTERFACE"
fi

exit 0

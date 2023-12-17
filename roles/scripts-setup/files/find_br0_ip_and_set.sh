#!/bin/bash

# Define the network prefix
network_prefix="120.13.212"
start_ip=254
end_ip=247

. ./logging.inc

# Function to check if br0 has a valid IP address
check_br0_ip() {
    local ip_address
    local max_attempts=30  # Number of attempts (with a 1-second delay between each)
    local attempt=0

    while [ $attempt -lt $max_attempts ]; do
        ip_address=$(nmcli -g IP4.ADDRESS dev show br0 | cut -d'/' -f1)

        if [[ "$ip_address" =~ ^169\.254\. ]]; then
            log_message "find_br0_ip_and_set" "INFO" "br0 has a Zeroconf address: $ip_address. Proceeding to check for available IPs."
            return  # Proceed with the rest of the script
        elif [ -n "$ip_address" ]; then
            log_message "find_br0_ip_and_set" "INFO" "br0 has a valid non-Zeroconf IP address: $ip_address. Exiting."
            exit 0  # Exit the script as a valid IP address is assigned
        else
            log_message "find_br0_ip_and_set" "DEBUG" "Waiting for IP address to be assigned to br0 (attempt $((attempt + 1))/$max_attempts)."
            sleep 1
        fi

        ((attempt++))
    done

    log_message "find_br0_ip_and_set" "WARN" "br0 did not receive an IP address within the expected time frame. Proceeding with IP assignment."
}
# Check br0 for a valid IP address
check_br0_ip


available_ip=""
for ip in $(seq $start_ip -1 $end_ip); do
    if arping -0 -c 2 -w 3 -I br0 $network_prefix.$ip | grep -q "Timeout"; then
        log_message "INFO" "Available IP: $network_prefix.$ip"
        available_ip="$network_prefix.$ip"
        available_gw="$network_prefix.1"
        break
    else
        log_message "find_br0_ip_and_set" "DEBUG" "IP $network_prefix.$ip is in use. Checking next."
    fi
done

# Check if an available IP was found
if [ -z "$available_ip" ]; then
    log_message "find_br0_ip_and_set" "WARN" "No available $network_prefix.x addresses in the specified range. Exiting."
    exit 1
else
    log_message "find_br0_ip_and_set" "INFO" "Assigning new IP:$available_ip and gateway:$available_gw to br0"
    nmcli con down br0
    nmcli con mod br0 ipv4.method auto
    nmcli con mod br0 ipv4.gateway ""
    nmcli con mod br0 ipv4.addresses ""
    nmcli con mod br0 ipv4.method manual ipv4.addresses $available_ip/24 ipv4.gateway $available_gw
    nmcli con up br0
fi

exit 0

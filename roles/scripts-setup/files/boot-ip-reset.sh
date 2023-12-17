#!/bin/bash


# Source the logging functions
. ./logging.inc


# Define the bridge interface
interface="br0"

# Check if the interface is already up
if nmcli device status | grep -q "$interface.*connected"; then
    log_message "boot-ip-reset" "INFO" "Interface '$interface' is already up. No action taken."
else
    # Set the interface to use DHCP
    nmcli con down $interface
    log_message "boot-ip-reset" "DEBUG" "Interface '$interface' set down."
    nmcli con mod $interface ipv4.method auto
    log_message "boot-ip-reset" "DEBUG" "Interface '$interface' set to use DHCP."
    nmcli con mod $interface ipv4.gateway ""
    log_message "boot-ip-reset" "DEBUG" "Interface '$interface' ipv4 gateway cleared."
    nmcli con mod $interface ipv4.addresses ""
    log_message "boot-ip-reset" "DEBUG" "Interface '$interface' ipv4 addresses cleared.."
    nmcli con up $interface
    log_message "boot-ip-reset" "DEBUG" "Interface '$interface' set up."
    #nmcli device connect $interface
    log_message "boot-ip-reset" "INFO" "Interface '$interface' set to use DHCP."
fi

exit 0

#!/bin/bash


# Source the logging functions

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

# Check if the interface is already up
if nmcli device status | grep -q "$INTERFACE.*connected"; then
    log_message "boot-ip-reset" "INFO" "Interface '$INTERFACE' is already up. No action taken."
else
    # Set the interface to use DHCP
    nmcli con down $INTERFACE
    log_message "boot-ip-reset" "DEBUG" "Interface '$INTERFACE' set down."
    nmcli con mod $INTERFACE ipv4.method auto
    log_message "boot-ip-reset" "DEBUG" "Interface '$INTERFACE' set to use DHCP."
    nmcli con mod $INTERFACE ipv4.gateway ""
    log_message "boot-ip-reset" "DEBUG" "Interface '$INTERFACE' ipv4 gateway cleared."
    nmcli con mod $INTERFACE ipv4.addresses ""
    log_message "boot-ip-reset" "DEBUG" "Interface '$INTERFACE' ipv4 addresses cleared.."
    nmcli con up $INTERFACE
    log_message "boot-ip-reset" "DEBUG" "Interface '$INTERFACE' set up."
    #nmcli device connect $interface
    log_message "boot-ip-reset" "INFO" "Interface '$INTERFACE' set to use DHCP."
fi

exit 0

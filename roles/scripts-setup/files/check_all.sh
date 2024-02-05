#!/bin/bash

# Get the directory where the script is located
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [[ -f "$DIR/check_bridge.sh" ]]; then
    # shellcheck disable=SC1091
    . "$DIR/check_bridge.sh"

else
    echo "Error: $DIR/check_bridge.sh not found."
    exit 1
fi

if [[ -f "$DIR/check_dhcp.sh" ]]; then
    # shellcheck disable=SC1091
    . "$DIR/check_dhcp.sh"

else
    echo "Error: $DIR/check_dhcp.sh not found."
    exit 1
fi

if [[ -f "$DIR/check_static.sh" ]]; then
    # shellcheck disable=SC1091
    . "$DIR/check_static.sh"

else
    echo "Error: $DIR/check_static.sh not found."
    exit 1
fi

if [[ -f "$DIR/check_link.sh" ]]; then
    # shellcheck disable=SC1091
    . "$DIR/check_link.sh"

else
    echo "Error: $DIR/check_link.sh not found."
    exit 1
fi

if [[ -f "$DIR/rtshark-scripts-settings.inc" ]]; then
    # shellcheck disable=SC1091
    . "$DIR/rtshark-scripts-settings.inc"
else
    echo "Error: $DIR/rtshark-scripts-settings.inc not found."
    exit 1
fi

if [[ -f "$DIR/logging.inc" ]]; then
    # shellcheck disable=SC1091
    . "$DIR/logging.inc"
else
    echo "Error: $DIR/logging.inc not found."
    exit 1
fi


if [[ -f "$DIR/fix_dhcp_failed.sh" ]]; then
    # shellcheck disable=SC1091
    . "$DIR/fix_dhcp_failed.sh"

else
    echo "Error: $DIR/fix_dhcp_failed.sh not found."
    exit 1
fi

if [[ -f "$DIR/fix_zc_address.sh" ]]; then
    # shellcheck disable=SC1091
    . "$DIR/fix_zc_address.sh"

else
    echo "Error: $DIR/fix_zc_address.sh not found."
    exit 1
fi

# Parse named arguments that override default values
while [[ $# -gt 0 ]]; do
    case $1 in
        --interface)
            INTERFACE="$2"
            log_message $SCRIPT_NAME "INFO" "Interface is overridden with $INTERFACE"
            shift # Remove argument name
            shift # Remove argument value
            ;;
        --network-prefix)
            NETWORK_PREFIX="$2"
            log_message $SCRIPT_NAME "INFO" "NETWORK_PREFIX is overridden with $NETWORK_PREFIX"
            shift # Remove argument name
            shift # Remove argument value
            ;;
        --script-name)
            SCRIPT_NAME="$2"
            log_message $SCRIPT_NAME "INFO" "SCRIPT_NAME is overridden with $SCRIPT_NAME"
            shift # Remove argument name
            shift # Remove argument value
            ;;
        *)    # Unknown option
            log_message $SCRIPT_NAME "INFO" "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Main loop
end_time=$((SECONDS + MAX_WAIT_TIME_FOR_DHCP))


# Wait until at least one slave link is up
while ! check_slave_links; do
    log_message $SCRIPT_NAME "INFO" "check_all: Waiting for a slave link to come up..."
    sleep $CHECK_INTERVAL
    if [[ $SECONDS -gt $end_time ]]; then
        log_message $SCRIPT_NAME "INFO" "check_all: Timeout waiting for a slave link to come up. Exiting without IP assignment."
        exit 1
    fi
done

# Reset the end_time once a link is up
end_time=$((SECONDS + MAX_WAIT_TIME_FOR_DHCP))

# Now proceed to check DHCP assignment
while [[ $SECONDS -lt $end_time ]]; do
    if check_interface_dhcp $INTERFACE; then
        log_message $SCRIPT_NAME "INFO" "check_all: DHCP has assigned an IP to $INTERFACE. Exiting the script."
        exit 0
    fi
    if check_static_ip $INTERFACE; then
        log_message $SCRIPT_NAME "INFO" "check_all: Interface $INTERFACE Static IP check passed."
        exit 0
    fi

    # Check the $INTERFACE state
    if check_br_state $INTERFACE; then
        log_message $SCRIPT_NAME "INFO" "check_all: Waiting for DHCP to assign an IP to $INTERFACE..."
        sleep $CHECK_INTERVAL
    else
        log_message $SCRIPT_NAME "INFO" "check_all: $INTERFACE is not in a connecting/connected state or DHCP failed."
        break
    fi
done

log_message $SCRIPT_NAME "INFO" "Timeout waiting for DHCP to assign an IP to $INTERFACE."
# Implement logic for handling DHCP failure
fix_dhcp_failed && log_message $SCRIPT_NAME "INFO" "Success: Static zeroconf address assigned" || (log_message $SCRIPT_NAME "INFO" "Failure: Could not assign static zeroconf address" && exit 1)

fix_zc_address $NETWORK_PREFIX $START_IP $END_IP $INTERFACE && log_message $SCRIPT_NAME "INFO" "Success: Static zeroconf address changed" || (log_message $SCRIPT_NAME "INFO" "Failure: Could not assign static non-zeroconf address" && exit 1)

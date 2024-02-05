#!/bin/bash

# Function to check the state of a given interface
function check_br_state() {
    local interface_name=$1
    local interface_state
    log_message $SCRIPT_NAME "DEBUG" "In check_br_state"
    interface_state=$(nmcli -t -f GENERAL.STATE con show "$interface_name" 2>/dev/null | cut -d: -f2 | xargs)

    if [[ -z "$interface_state" ]]; then
        log_message $SCRIPT_NAME "DEBUG" "check_br_state: The state of $interface_name is not available."
        return 1
    fi

    case "$interface_state" in
        "activated")
            log_message $SCRIPT_NAME "DEBUG" "check_br_state: $interface_name is connected."
            return 0
            ;;
        "activating"|"getting IP configuration")
            log_message $SCRIPT_NAME "DEBUG" "check_br_state: $interface_name is connecting."
            return 0
            ;;
        *)
            log_message $SCRIPT_NAME "DEBUG" "check_br_state: $interface_name is in an unexpected state: $interface_state."
            return 1
            ;;
    esac
}

# Usage example
#INTERFACE=br0
#if check_br_state "$INTERFACE"; then
#    echo "$INTERFACE is in a valid state (connected or connecting)."
#else
#    echo "$INTERFACE is in an invalid state or state is not available."
#fi

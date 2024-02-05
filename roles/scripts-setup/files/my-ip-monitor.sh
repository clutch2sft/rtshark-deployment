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

if [[ -n "$1" ]]; then
    INTERFACE="$1"
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

while true; do
    current_ip=$(nmcli -t -f IP4.ADDRESS dev show $INTERFACE | awk -F: '{print $2}' | cut -d'/' -f1)
    if [ -z "$current_ip" ]; then
        log_message "my-ip-monitor" "WARN" "No IP address found on $INTERFACE. Skipping arping check."
    else
        # Check for timeout response
        if ! run_arping "$current_ip"; then
            log_message "my-ip-monitor" "ERROR" "IP conflict detected for $current_ip. Reverting to fallback IP."
            nmcli con down $INTERFACE
            nmcli con mod $INTERFACE ipv4.method auto
            nmcli con up $INTERFACE
            systemctl restart find_interface_ip_and_set@br0.service
        else
            log_message "my-ip-monitor" "DEBUG" "No IP conflict detected for $current_ip."
        fi
    fi
    sleep 60
done
